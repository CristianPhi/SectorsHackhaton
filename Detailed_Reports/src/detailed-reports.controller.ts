import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Query,
} from "@nestjs/common";
import { DetailedReportsService } from "./detailed-reports.service";

@Controller("reports")
export class DetailedReportsController {
  constructor(private readonly reportsService: DetailedReportsService) {}

  @Get("company/:symbol")
  getCompanyReport(
    @Param("symbol") symbol: string,
    @Query("sections") sections?: string,
  ) {
    return this.reportsService.getCompanyReport(symbol, sections);
  }

  @Get("shareholders/:symbol")
  getShareholders(
    @Param("symbol") symbol: string,
    @Query("year") year?: string,
  ) {
    return this.reportsService.getShareholders(
      symbol,
      this.parseOptionalInteger(year, "year"),
    );
  }

  @Get("quarterly/:symbol")
  getQuarterlyFinancials(
    @Param("symbol") symbol: string,
    @Query("report_date") reportDate?: string,
    @Query("approx") approx?: string,
    @Query("n_quarters") nQuarters?: string,
  ) {
    return this.reportsService.getQuarterlyFinancials(symbol, {
      report_date: reportDate,
      approx: approx === undefined ? undefined : approx !== "false",
      n_quarters: this.parseOptionalInteger(nQuarters, "n_quarters"),
    });
  }

  private parseOptionalInteger(value: string | undefined, name: string) {
    if (value === undefined) {
      return undefined;
    }

    const parsedValue = Number(value);
    if (!Number.isInteger(parsedValue)) {
      throw new BadRequestException(`${name} must be an integer`);
    }

    return parsedValue;
  }
}
