import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import * as nodemailer from 'nodemailer';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { User, UserDocument } from './schemas/user.schema';

@Injectable()
export class AuthService {
  constructor(@InjectModel(User.name) private readonly userModel: Model<UserDocument>) {}

  private normalizeUsername(value: string) {
    return value.trim().toLowerCase();
  }

  private requiresEmailVerification(): boolean {
    const value = (process.env.EMAIL_VERIFICATION_REQUIRED ?? 'false').trim().toLowerCase();
    return value === 'true' || value === '1' || value === 'yes';
  }

  private generateCode() {
    return String(Math.floor(100000 + Math.random() * 900000));
  }

  private async sendEmail(to: string, subject: string, text: string, html?: string): Promise<boolean> {
    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT ?? 587);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;
    const from = process.env.EMAIL_FROM ?? 'no-reply@sectors.local';

    if (!host || !user || !pass || !from) {
      console.warn(
        'SMTP belum dikonfigurasi. Email verifikasi dilewati agar registrasi tetap bisa dipakai di lokal.',
      );
      return false;
    }

    try {
      const transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });

      await transporter.sendMail({
        from,
        to,
        subject,
        text,
        html,
      });
      return true;
    } catch (error) {
      console.warn('Email tidak terkirim. Registrasi tetap dilanjutkan.', error);
      return false;
    }
  }

  private async setEmailVerificationCode(user: UserDocument) {
    const code = this.generateCode();
    user.emailVerificationCode = code;
    user.emailVerificationExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();
    const emailSent = await this.sendEmail(
      user.email,
      'Verifikasi email akun Anda',
      `Kode verifikasi Anda adalah ${code}. Kode berlaku 10 menit.`,
    );
    return { code, emailSent };
  }

  private async setPasswordResetCode(user: UserDocument) {
    const code = this.generateCode();
    user.passwordResetCode = code;
    user.passwordResetExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();
    const emailSent = await this.sendEmail(
      user.email,
      'Reset password akun Anda',
      `Kode reset password Anda adalah ${code}. Kode berlaku 10 menit.`,
    );
    return { code, emailSent };
  }

  async register(dto: RegisterDto) {
    const email = dto.email.toLowerCase().trim();
    const username = this.normalizeUsername(dto.username);

    if (dto.password !== dto.confirmPassword) {
      throw new BadRequestException('Konfirmasi password tidak cocok.');
    }

    if (!username) {
      throw new BadRequestException('Username wajib diisi.');
    }

    const existingUser = await this.userModel.findOne({ $or: [{ email }, { username }] }).lean();
    if (existingUser) {
      if (existingUser.email === email) {
        throw new ConflictException('Email sudah terdaftar');
      }
      throw new ConflictException('Username sudah diambil, silakan pilih username lain.');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.userModel.create({
      username,
      name: dto.name.trim(),
      email,
      passwordHash,
      emailVerified: false,
      watchlist: [],
      chatHistory: [],
    });

    const verification = await this.setEmailVerificationCode(user);

    return {
      id: String(user._id),
      name: user.name,
      displayName: user.name,
      email: user.email,
      emailVerified: false,
      isGoogle: false,
      emailVerificationSent: verification.emailSent,
      message: verification.emailSent
        ? 'Akun berhasil dibuat. Kode verifikasi telah dikirim ke email Anda.'
        : 'Akun berhasil dibuat, tetapi email verifikasi tidak terkirim.',
      ...(!verification.emailSent && process.env.NODE_ENV !== 'production'
        ? { developmentCode: verification.code }
        : {}),
    };
  }

  async resendVerificationEmail(email: string) {
    const normalized = email.toLowerCase().trim();
    const user = await this.userModel.findOne({ email: normalized });

    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }

    if (user.emailVerified) {
      return {
        email: user.email,
        emailVerified: true,
        message: 'Email sudah diverifikasi.',
      };
    }

    const verification = await this.setEmailVerificationCode(user);

    return {
      email: user.email,
      emailVerified: false,
      emailVerificationSent: verification.emailSent,
      message: verification.emailSent
        ? 'Kode verifikasi baru telah dikirim ke email Anda.'
        : 'Email verifikasi tidak terkirim.',
      ...(!verification.emailSent && process.env.NODE_ENV !== 'production'
        ? { developmentCode: verification.code }
        : {}),
    };
  }

  async verifyEmail(dto: VerifyEmailDto) {
    const email = dto.email.toLowerCase().trim();
    const user = await this.userModel.findOne({ email });

    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }

    if (user.emailVerified) {
      return { email, emailVerified: true, message: 'Email sudah diverifikasi.' };
    }

    if (!user.emailVerificationCode || !user.emailVerificationExpiresAt) {
      throw new BadRequestException('Kode verifikasi tidak tersedia. Silakan kirim ulang kode.');
    }

    if (new Date(user.emailVerificationExpiresAt).getTime() < Date.now()) {
      throw new BadRequestException('Kode verifikasi sudah kadaluarsa. Silakan kirim ulang.');
    }

    if (user.emailVerificationCode !== dto.code) {
      throw new BadRequestException('Kode verifikasi salah.');
    }

    user.emailVerified = true;
    user.emailVerificationCode = null;
    user.emailVerificationExpiresAt = null;
    await user.save();

    return {
      email: user.email,
      emailVerified: true,
      message: 'Email berhasil diverifikasi.',
    };
  }

  async login(dto: LoginDto) {
    const submittedValue = dto.email.trim();
    const normalized = submittedValue.toLowerCase();
    const user = await this.userModel
      .findOne({
        $or: [{ email: normalized }, { username: this.normalizeUsername(submittedValue) }],
      })
      .select('+passwordHash');

    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash ?? ''))) {
      throw new UnauthorizedException('Email atau password salah');
    }

    if (this.requiresEmailVerification() && !user.emailVerified) {
      throw new UnauthorizedException('Email belum diverifikasi. Silakan verifikasi kode yang dikirim ke email Anda.');
    }

    if (!user.username || !user.username.trim()) {
      const fallbackUsername = this.normalizeUsername(
        (user.name || user.email.split('@')[0] || 'user').replace(/\s+/g, '.'),
      );
      const safeUsername = fallbackUsername || `user${Math.random().toString(36).slice(2, 8)}`;
      const existing = await this.userModel.exists({
        username: safeUsername,
        _id: { $ne: user._id },
      });

      user.username = existing ? `${safeUsername}${Math.random().toString(36).slice(2, 6)}` : safeUsername;
    }

    user.lastLoginAt = new Date();
    await user.save();

    return {
      id: String(user._id),
      name: user.name,
      displayName: user.name,
      email: user.email,
      emailVerified: user.emailVerified,
      isGoogle: false,
    };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const email = dto.email.toLowerCase().trim();
    const user = await this.userModel.findOne({ email });

    if (!user) {
      return {
        message: 'Jika email terdaftar, kode reset password sudah dikirim.',
      };
    }

    const reset = await this.setPasswordResetCode(user);
    if (!reset.emailSent && process.env.NODE_ENV === 'production') {
      throw new ServiceUnavailableException('Email reset tidak dapat dikirim saat ini. Silakan coba lagi nanti.');
    }

    return {
      message: reset.emailSent
        ? 'Kode reset password telah dikirim ke email Anda.'
        : 'Email SMTP belum tersedia. Gunakan kode reset lokal untuk development.',
      ...(!reset.emailSent ? { developmentCode: reset.code } : {}),
    };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const email = dto.email.toLowerCase().trim();
    const user = await this.userModel.findOne({ email });

    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }

    if (dto.password !== dto.confirmPassword) {
      throw new BadRequestException('Konfirmasi password tidak cocok.');
    }

    if (!user.passwordResetCode || !user.passwordResetExpiresAt) {
      throw new BadRequestException('Kode reset password belum dibuat atau sudah kedaluwarsa.');
    }

    if (new Date(user.passwordResetExpiresAt).getTime() < Date.now()) {
      throw new BadRequestException('Kode reset password sudah kedaluwarsa.');
    }

    if (user.passwordResetCode !== dto.code) {
      throw new BadRequestException('Kode reset password salah.');
    }

    user.passwordHash = await bcrypt.hash(dto.password, 12);
    user.passwordResetCode = null;
    user.passwordResetExpiresAt = null;
    await user.save();

    return {
      message: 'Password berhasil diubah.',
    };
  }

  async checkUsernameAvailability(username: string) {
    const cleanUsername = this.normalizeUsername(username);
    if (!cleanUsername) {
      return { available: false, username: '', message: 'Username wajib diisi.' };
    }

    const exists = await this.userModel.exists({ username: cleanUsername });
    return {
      available: !exists,
      username: cleanUsername,
      message: exists ? 'Username sudah diambil, silakan pilih username lain.' : 'Username tersedia.',
    };
  }

  async getUserById(userId: string) {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }

    return {
      id: String(user._id),
      name: user.name,
      displayName: user.name,
      email: user.email,
      emailVerified: user.emailVerified,
      isGoogle: false,
      watchlist: user.watchlist ?? [],
      chatHistory: user.chatHistory ?? [],
      lastLoginAt: user.lastLoginAt,
    };
  }

  async getWatchlist(userId: string) {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }
    return { userId, watchlist: user.watchlist ?? [] };
  }

  async addToWatchlist(userId: string, ticker: string) {
    const cleanTicker = ticker.trim().toUpperCase();
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }

    const existing = user.watchlist ?? [];
    if (!existing.includes(cleanTicker)) {
      existing.push(cleanTicker);
      user.watchlist = existing;
      await user.save();
    }

    return { userId, watchlist: user.watchlist ?? [] };
  }

  async removeFromWatchlist(userId: string, ticker: string) {
    const cleanTicker = ticker.trim().toUpperCase();
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }

    user.watchlist = (user.watchlist ?? []).filter((item) => item !== cleanTicker);
    await user.save();

    return { userId, watchlist: user.watchlist ?? [] };
  }

  async getChatHistory(userId: string) {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }
    return { userId, chatHistory: user.chatHistory ?? [] };
  }

  async addChatHistory(userId: string, prompt: string, response: string) {
    const user = await this.userModel.findById(userId);
    if (!user) {
      throw new NotFoundException('User tidak ditemukan');
    }

    const history = user.chatHistory ?? [];
    history.push({
      prompt: prompt.trim(),
      response: response.trim(),
      createdAt: new Date(),
    });

    user.chatHistory = history.slice(-50);
    await user.save();

    return { userId, chatHistory: user.chatHistory ?? [] };
  }
}
