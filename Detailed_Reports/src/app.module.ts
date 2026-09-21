import { Module } from "@nestjs/common";
import { HttpModule } from "@nestjs/axios";
import { DetailedReportsController } from "./detailed-reports.controller";
import { DetailedReportsService } from "./detailed-reports.service";

@Module({
  imports: [HttpModule],
  controllers: [DetailedReportsController],
  providers: [DetailedReportsService],
})
export class AppModule {}
