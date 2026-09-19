import { BrokerService } from './broker.service';
export declare class BrokerController {
    private readonly brokerService;
    constructor(brokerService: BrokerService);
    getBrokers(): Promise<any[]>;
    getTopBrokers(): Promise<any>;
    getBrokerActivity(brokerCode: string): Promise<any>;
    getBrokerActivityTop(brokerCode: string): Promise<any>;
    getBrokerSummary(symbol: string): Promise<any>;
    getBrokerSummaryTop(symbol: string): Promise<any>;
    getForeignFlow(limit?: string): Promise<any>;
    getForeignFlowBySymbol(symbol: string): Promise<any>;
}
