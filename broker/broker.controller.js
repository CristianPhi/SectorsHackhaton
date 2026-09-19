"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BrokerController = void 0;
const common_1 = require("@nestjs/common");
const broker_service_1 = require("./broker.service");
let BrokerController = class BrokerController {
    brokerService;
    constructor(brokerService) {
        this.brokerService = brokerService;
    }
    getBrokers() {
        return this.brokerService.getBrokers();
    }
    getTopBrokers() {
        return this.brokerService.getTopBrokers();
    }
    getBrokerActivity(brokerCode) {
        return this.brokerService.getBrokerActivity(brokerCode);
    }
    getBrokerActivityTop(brokerCode) {
        return this.brokerService.getBrokerActivityTop(brokerCode);
    }
    getBrokerSummary(symbol) {
        return this.brokerService.getBrokerSummary(symbol);
    }
    getBrokerSummaryTop(symbol) {
        return this.brokerService.getBrokerSummaryTop(symbol);
    }
    getForeignFlow(limit) {
        const parsedLimit = limit ? Number(limit) : 20;
        return this.brokerService.getForeignFlow();
    }
    getForeignFlowBySymbol(symbol) {
        return this.brokerService.getForeignFlowBySymbol(symbol);
    }
};
exports.BrokerController = BrokerController;
__decorate([
    (0, common_1.Get)('brokers'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BrokerController.prototype, "getBrokers", null);
__decorate([
    (0, common_1.Get)('brokers/top'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BrokerController.prototype, "getTopBrokers", null);
__decorate([
    (0, common_1.Get)('activity/:brokerCode'),
    __param(0, (0, common_1.Param)('brokerCode')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BrokerController.prototype, "getBrokerActivity", null);
__decorate([
    (0, common_1.Get)('activity/:brokerCode/top'),
    __param(0, (0, common_1.Param)('brokerCode')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BrokerController.prototype, "getBrokerActivityTop", null);
__decorate([
    (0, common_1.Get)('summary/:symbol'),
    __param(0, (0, common_1.Param)('symbol')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BrokerController.prototype, "getBrokerSummary", null);
__decorate([
    (0, common_1.Get)('summary/:symbol/top'),
    __param(0, (0, common_1.Param)('symbol')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BrokerController.prototype, "getBrokerSummaryTop", null);
__decorate([
    (0, common_1.Get)('foreign-flow'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BrokerController.prototype, "getForeignFlow", null);
__decorate([
    (0, common_1.Get)('foreign-flow/:symbol'),
    __param(0, (0, common_1.Param)('symbol')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BrokerController.prototype, "getForeignFlowBySymbol", null);
exports.BrokerController = BrokerController = __decorate([
    (0, common_1.Controller)('broker'),
    __metadata("design:paramtypes", [broker_service_1.BrokerService])
], BrokerController);
//# sourceMappingURL=broker.controller.js.map