import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import { ForgotPasswordDto } from './dto/forgot-password.dto.js';
import { LoginDto } from './dto/login.dto.js';
import { RegisterDto } from './dto/register.dto.js';
import { ResetPasswordDto } from './dto/reset-password.dto.js';
import { VerifyEmailDto } from './dto/verify-email.dto.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('resend-verification')
  resendVerification(@Body('email') email: string) {
    return this.authService.resendVerificationEmail(email);
  }

  @Post('verify-email')
  verifyEmail(@Body() dto: VerifyEmailDto) {
    return this.authService.verifyEmail(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('check-username')
  checkUsername(@Body('username') username: string) {
    return this.authService.checkUsernameAvailability(username);
  }

  @Post('forgot-password')
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  @Post('reset-password')
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto);
  }

  @Get('user/:userId')
  getUser(@Param('userId') userId: string) {
    return this.authService.getUserById(userId);
  }

  @Get('watchlist/:userId')
  getWatchlist(@Param('userId') userId: string) {
    return this.authService.getWatchlist(userId);
  }

  @Post('watchlist/:userId')
  addWatchlist(@Param('userId') userId: string, @Body('ticker') ticker: string) {
    return this.authService.addToWatchlist(userId, ticker);
  }

  @Post('watchlist/:userId/remove')
  removeWatchlist(@Param('userId') userId: string, @Body('ticker') ticker: string) {
    return this.authService.removeFromWatchlist(userId, ticker);
  }

  @Get('chat-history/:userId')
  getChatHistory(@Param('userId') userId: string) {
    return this.authService.getChatHistory(userId);
  }

  @Post('chat-history/:userId')
  addChatHistory(
    @Param('userId') userId: string,
    @Body() body: { prompt: string; response: string },
  ) {
    return this.authService.addChatHistory(userId, body.prompt, body.response);
  }
}
