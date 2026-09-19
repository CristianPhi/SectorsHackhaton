"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BrokerService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = __importDefault(require("axios"));
let BrokerService = class BrokerService {
    baseUrl = 'https://api.sectors.app/v2';
    headers = {
        Authorization: process.env.SECTORS_API_KEY,
    };
    async request(path, params = {}) {
        if (!process.env.SECTORS_API_KEY) {
            throw new common_1.ServiceUnavailableException('SECTORS_API_KEY belum diatur di file .env');
        }
        const response = await axios_1.default.get(`${this.baseUrl}${path}`, {
            headers: this.headers,
            params,
        });
        return response.data;
    }
    async getBrokers() {
        return this.request('/brokers/');
    }
    async getTopBrokers() {
        return this.request('/brokers/top/');
    }
    async getBrokerActivity(brokerCode) {
        const cleanCode = brokerCode.trim().toUpperCase();
        return this.request(`/broker-activity/${cleanCode}/`);
    }
    async getBrokerActivityTop(brokerCode) {
        const cleanCode = brokerCode.trim().toUpperCase();
        return this.request(`/broker-activity/${cleanCode}/top/`);
    }
    async getBrokerSummary(symbol) {
        const cleanSymbol = symbol.trim().toUpperCase().replace(/\.JK$/i, '');
        return this.request(`/broker-summary/${cleanSymbol}/`);
    }
    async getBrokerSummaryTop(symbol) {
        const cleanSymbol = symbol.trim().toUpperCase().replace(/\.JK$/i, '');
        return this.request(`/broker-summary/${cleanSymbol}/top/`);
    }
    async getForeignFlow() {
        return this.request('/foreign-flow/', {
            order_by: '-net_foreign_inflow',
            limit: 20,
        });
    }
    async getForeignFlowBySymbol(symbol) {
        const cleanSymbol = symbol.trim().toUpperCase().replace(/\.JK$/i, '');
        return this.request(`/foreign-flow/${cleanSymbol}/`);
    }
};
exports.BrokerService = BrokerService;
exports.BrokerService = BrokerService = __decorate([
    (0, common_1.Injectable)()
], BrokerService);
//# sourceMappingURL=broker.service.js.map