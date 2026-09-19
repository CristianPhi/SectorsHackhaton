export declare class BrokerService {
    private readonly baseUrl;
    private readonly headers;
    private request;
    getBrokers(): Promise<any[]>;
    getTopBrokers(): Promise<any>;
    getBrokerActivity(brokerCode: string): Promise<any>;
    getBrokerActivityTop(brokerCode: string): Promise<any>;
    getBrokerSummary(symbol: string): Promise<any>;
    getBrokerSummaryTop(symbol: string): Promise<any>;
    getForeignFlow(): Promise<any>;
    getForeignFlowBySymbol(symbol: string): Promise<any>;
}
