import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

@Schema({ timestamps: true, collection: 'users' })
export class User {
  @Prop({ required: true, trim: true })
  name: string;

  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  username: string;

  @Prop({ required: true, unique: true, lowercase: true, trim: true })
  email: string;

  @Prop({ type: String, default: null, select: false })
  passwordHash?: string | null;

  @Prop({ default: false })
  emailVerified: boolean;

  @Prop({ type: String, default: null })
  emailVerificationCode?: string | null;

  @Prop({ type: Date, default: null })
  emailVerificationExpiresAt?: Date | null;

  @Prop({ type: String, default: null })
  passwordResetCode?: string | null;

  @Prop({ type: Date, default: null })
  passwordResetExpiresAt?: Date | null;

  @Prop({ type: [String], default: [] })
  watchlist: string[];

  @Prop({
    type: [
      {
        prompt: { type: String, required: true },
        response: { type: String, required: true },
        createdAt: { type: Date, default: Date.now },
      },
    ],
    default: [],
  })
  chatHistory: Array<{
    prompt: string;
    response: string;
    createdAt: Date;
  }>;

  @Prop({ type: Date, default: null })
  lastLoginAt?: Date | null;
}

export const UserSchema = SchemaFactory.createForClass(User);
