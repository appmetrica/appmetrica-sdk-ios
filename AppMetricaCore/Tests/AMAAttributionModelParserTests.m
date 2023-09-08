
#import <Kiwi/Kiwi.h>
#import "AMAInternalEventsReporter.h"
#import "AMAAttributionModelParser.h"
#import "AMAAttributionModelConfiguration.h"
#import "AMAConversionAttributionModelConfiguration.h"
#import "AMAEngagementAttributionModelConfiguration.h"
#import "AMARevenueAttributionModelConfiguration.h"
#import "AMAAttributionMapping.h"
#import "AMAEventFilter.h"
#import "AMAClientEventCondition.h"
#import "AMARevenueEventCondition.h"
#import "AMAECommerceEventCondition.h"
#import "AMABoundMapping.h"
#import "AMAAttributionConvertingUtils.h"
#import "AMACurrencyMapping.h"

SPEC_BEGIN(AMAAttributionModelParserTests)

describe(@"AMAAttributionModelParser", ^{

    AMAInternalEventsReporter *__block reporter = nil;
    AMAAttributionModelParser *__block parser = nil;
    beforeEach(^{
        reporter = [AMAInternalEventsReporter nullMock];
        parser = [[AMAAttributionModelParser alloc] initWithReporter:reporter];
    });
    context(@"Valid JSON for engagement", ^{
        AMAAttributionModelConfiguration *__block config = nil;
        NSDictionary *json = @{
            @"sending_stop_time_seconds" : @777888,
            @"max_saved_revenue_ids" : @56,
            @"model_type" : @"engagement",
            @"engagement_model": @{
                @"mapping": @[
                    @{
                        @"bound" : @10,
                        @"value" : @3,
                    },
                    @{
                        @"bound" : @4,
                        @"value" : @5,
                    },
                ],
                @"events" : @[
                    @{
                        @"event_type" : @"client",
                        @"client_events_conditions" : @{
                            @"event_name" : @"some name"
                        }
                    },
                    @{
                        @"event_type" : @"revenue",
                        @"revenue_events_conditions" : @{
                            @"source" : @"api"
                        }
                    },
                    @{
                        @"event_type" : @"ecom",
                        @"ecom_events_conditions" : @{
                            @"ecom_type" : @"purchase"
                        }
                    },
                    @{
                        @"event_type" : @"client",
                        @"client_events_conditions" : @{
                            @"event_name" : @"another name"
                        }
                    },
                ]
            }
        };
        beforeEach(^{
            config = [parser parse:json];
        });
        it(@"Should not report error", ^{
            [[reporter shouldNot] receive:@selector(reportSKADAttributionParsingError:)];
            config = [parser parse:json];
        });
        it(@"Should parse stop time sending seconds", ^{
            [[config.stopSendingTimeSeconds should] equal:@777888];
        });
        it(@"Should parse max saved revenue ids", ^{
            [[config.maxSavedRevenueIDs should] equal:@56];
        });
        it(@"Max saved revenue ids should be default", ^{
            NSMutableDictionary *newJSON = [json mutableCopy];
            newJSON[@"max_saved_revenue_ids"] = nil;
            config = [parser parse:newJSON];
            [[config.maxSavedRevenueIDs should] equal:@50];
        });
        it(@"Should parse model type", ^{
            [[theValue(config.type) should] equal:theValue(AMAAttributionModelTypeEngagement)];
            [[AMAAttributionConvertingUtils should] receive:@selector(modelTypeForString:) withArguments:@"engagement"];
            [parser parse:json];
        });
        it(@"Conversion should be nil", ^{
            [[config.conversion should] beNil];
        });
        it(@"Revenue should be nil", ^{
            [[config.revenue should] beNil];
        });
        it(@"Engagement should not be nil", ^{
            [[config.engagement shouldNot] beNil];
        });
        context(@"Engagement", ^{
            // mappings are sorted by bound
            it(@"Bound mapping size should be 2", ^{
                [[theValue(config.engagement.boundMappings.count) should] equal:theValue(2)];
            });
            context(@"First mapping", ^{
                AMABoundMapping *__block mapping = nil;
                beforeEach(^{
                    mapping = config.engagement.boundMappings[0];
                });
                it(@"Should parse bound value", ^{
                    [[mapping.bound should] equal:[NSDecimalNumber decimalNumberWithString:@"4"]];
                });
                it(@"Should parse value", ^{
                    [[mapping.value should] equal:@5];
                });
            });
            context(@"Second mapping", ^{
                AMABoundMapping *__block mapping = nil;
                beforeEach(^{
                    mapping = config.engagement.boundMappings[1];
                });
                it(@"Should parse bound value", ^{
                    [[mapping.bound should] equal:[NSDecimalNumber decimalNumberWithString:@"10"]];
                });
                it(@"Should parse value", ^{
                    [[mapping.value should] equal:@3];
                });
            });
            it(@"Events count should be 4", ^{
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(4)];
            });
            it(@"Should proxy event type parsing", ^{
                [[AMAAttributionConvertingUtils should] receive:@selector(eventTypeForString:error:)
                                                      withCount:2
                                                      arguments:@"client", kw_any()];
                [[AMAAttributionConvertingUtils should] receive:@selector(eventTypeForString:error:) withArguments:@"revenue", kw_any()];
                [[AMAAttributionConvertingUtils should] receive:@selector(eventTypeForString:error:) withArguments:@"ecom", kw_any()];
                [parser parse:json];
            });
            context(@"First event filter", ^{
                AMAEventFilter *__block filter = nil;
                beforeEach(^{
                    filter = config.engagement.eventFilters[0];
                });
                it(@"Should parse event type", ^{
                    [[theValue(filter.type) should] equal:theValue(AMAEventTypeClient)];
                });
                it(@"Revenue conditions should be nil", ^{
                    [[filter.revenueEventCondition should] beNil];
                });
                it(@"ECommerce conditions should be nil", ^{
                    [[filter.eCommerceEventCondition should] beNil];
                });
                it(@"Should parse client event condition", ^{
                    [[theValue([filter.clientEventCondition checkEvent:@"some name"]) should] beYes];
                });
            });
            context(@"Second event filter", ^{
                AMAEventFilter *__block filter = nil;
                beforeEach(^{
                    filter = config.engagement.eventFilters[1];
                });
                it(@"Should parse event type", ^{
                    [[theValue(filter.type) should] equal:theValue(AMAEventTypeRevenue)];
                });
                it(@"Client conditions should be nil", ^{
                    [[filter.clientEventCondition should] beNil];
                });
                it(@"ECommerce conditions should be nil", ^{
                    [[filter.eCommerceEventCondition should] beNil];
                });
                it(@"Should parse revenue event condition", ^{
                    [[theValue([filter.revenueEventCondition checkEvent:NO]) should] beYes];
                    [[AMAAttributionConvertingUtils should] receive:@selector(revenueSourceForString:error:) withArguments:@"api", kw_any()];
                    [parser parse:json];
                });
            });
            context(@"Third event filter", ^{
                AMAEventFilter *__block filter = nil;
                beforeEach(^{
                    filter = config.engagement.eventFilters[2];
                });
                it(@"Should parse event type", ^{
                    [[theValue(filter.type) should] equal:theValue(AMAEventTypeECommerce)];
                });
                it(@"Revenue conditions should be nil", ^{
                    [[filter.revenueEventCondition should] beNil];
                });
                it(@"Client conditions should be nil", ^{
                    [[filter.clientEventCondition should] beNil];
                });
                it(@"Should parse ecom event condition", ^{
                    [[theValue([filter.eCommerceEventCondition checkEvent:AMAECommerceEventTypePurchase]) should] beYes];
                    [[AMAAttributionConvertingUtils should] receive:@selector(eCommerceTypeForString:error:) withArguments:@"purchase", kw_any()];
                    [parser parse:json];
                });
            });
            context(@"Fourth event filter", ^{
                AMAEventFilter *__block filter = nil;
                beforeEach(^{
                    filter = config.engagement.eventFilters[3];
                });
                it(@"Should parse event type", ^{
                    [[theValue(filter.type) should] equal:theValue(AMAEventTypeClient)];
                });
                it(@"Revenue conditions should be nil", ^{
                    [[filter.revenueEventCondition should] beNil];
                });
                it(@"ECommerce conditions should be nil", ^{
                    [[filter.eCommerceEventCondition should] beNil];
                });
                it(@"Should parse client event condition", ^{
                    [[theValue([filter.clientEventCondition checkEvent:@"another name"]) should] beYes];
                });
            });

        });
    });
    context(@"Valid JSON for conversion", ^{
        AMAAttributionModelConfiguration *__block config = nil;
        NSDictionary *json = @{
            @"sending_stop_time_seconds" : @777888,
            @"max_saved_revenue_ids" : @56,
            @"model_type" : @"conversion",
            @"conversion_model": @{
                @"mapping": @[
                    @{
                        @"conversion_value" : @2,
                        @"required_count" : @3,
                        @"events" : @[
                        @{
                            @"event_type" : @"client",
                            @"client_events_conditions" : @{
                                @"event_name" : @"some name"
                            }
                        },
                        @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source" : @"api"
                            }
                        },
                        @{
                            @"event_type" : @"ecom",
                            @"ecom_events_conditions" : @{
                                @"ecom_type" : @"purchase"
                            }
                        },
                        @{
                            @"event_type" : @"client",
                            @"client_events_conditions" : @{
                                @"event_name" : @"another name"
                            }
                        },
                    ]
                    },
                    @{
                        @"conversion_value" : @4,
                        @"required_count" : @1,
                        @"events" : @[
                        @{
                            @"event_type" : @"client",
                            @"client_events_conditions" : @{
                                @"event_name" : @"another mapping"
                            }
                        },
                        ]
                    },
                ]
            }
        };
        beforeEach(^{
            config = [parser parse:json];
        });
        it(@"should not report error", ^{
            [[reporter shouldNot] receive:@selector(reportSKADAttributionParsingError:)];
            config = [parser parse:json];
        });
        it(@"Should parse stop time sending seconds", ^{
            [[config.stopSendingTimeSeconds should] equal:@777888];
        });
        it(@"Should parse max saved revenue ids", ^{
            [[config.maxSavedRevenueIDs should] equal:@56];
        });
        it(@"Max saved revenue ids should be default", ^{
            NSMutableDictionary *newJSON = [json mutableCopy];
            newJSON[@"max_saved_revenue_ids"] = nil;
            config = [parser parse:newJSON];
            [[config.maxSavedRevenueIDs should] equal:@50];
        });
        it(@"Should parse model type", ^{
            [[theValue(config.type) should] equal:theValue(AMAAttributionModelTypeConversion)];
            [[AMAAttributionConvertingUtils should] receive:@selector(modelTypeForString:) withArguments:@"conversion"];
            [parser parse:json];
        });
        it(@"Engagement should be nil", ^{
            [[config.engagement should] beNil];
        });
        it(@"Revenue should be nil", ^{
            [[config.revenue should] beNil];
        });
        it(@"Conversion should not be nil", ^{
            [[config.conversion shouldNot] beNil];
        });
        context(@"Conversion", ^{
            it(@"Mapping size should be 2", ^{
                [[theValue(config.conversion.mappings.count) should] equal:theValue(2)];
            });
            it(@"Should proxy event type parsing", ^{
                [[AMAAttributionConvertingUtils should] receive:@selector(eventTypeForString:error:)
                                                      withCount:3
                                                      arguments:@"client", kw_any()];
                [[AMAAttributionConvertingUtils should] receive:@selector(eventTypeForString:error:) withArguments:@"revenue", kw_any()];
                [[AMAAttributionConvertingUtils should] receive:@selector(eventTypeForString:error:) withArguments:@"ecom", kw_any()];
                [parser parse:json];
            });
            context(@"First mapping", ^{
                AMAAttributionMapping *__block mapping = nil;
                beforeEach(^{
                    mapping = config.conversion.mappings[0];
                });
                it(@"Should parse conversion value", ^{
                    [[theValue(mapping.conversionValueDiff) should] equal:theValue(2)];
                });
                it(@"Should parse required count", ^{
                    [[theValue(mapping.requiredCount) should] equal:theValue(3)];
                });
                it(@"Events size should be 4", ^{
                    [[theValue(mapping.eventFilters.count) should] equal:theValue(4)];
                });
                context(@"First event filter", ^{
                    AMAEventFilter *__block filter = nil;
                    beforeEach(^{
                        filter = mapping.eventFilters[0];
                    });
                    it(@"Should parse event type", ^{
                        [[theValue(filter.type) should] equal:theValue(AMAEventTypeClient)];
                    });
                    it(@"Revenue conditions should be nil", ^{
                        [[filter.revenueEventCondition should] beNil];
                    });
                    it(@"ECommerce conditions should be nil", ^{
                        [[filter.eCommerceEventCondition should] beNil];
                    });
                    it(@"Should parse client event condition", ^{
                        [[theValue([filter.clientEventCondition checkEvent:@"some name"]) should] beYes];
                    });
                });
                context(@"Second event filter", ^{
                    AMAEventFilter *__block filter = nil;
                    beforeEach(^{
                        filter = mapping.eventFilters[1];
                    });
                    it(@"Should parse event type", ^{
                        [[theValue(filter.type) should] equal:theValue(AMAEventTypeRevenue)];
                    });
                    it(@"Client conditions should be nil", ^{
                        [[filter.clientEventCondition should] beNil];
                    });
                    it(@"ECommerce conditions should be nil", ^{
                        [[filter.eCommerceEventCondition should] beNil];
                    });
                    it(@"Should parse revenue event condition", ^{
                        [[theValue([filter.revenueEventCondition checkEvent:NO]) should] beYes];
                        [[AMAAttributionConvertingUtils should] receive:@selector(revenueSourceForString:error:) withArguments:@"api", kw_any()];
                        [parser parse:json];
                    });
                });
                context(@"Third event filter", ^{
                    AMAEventFilter *__block filter = nil;
                    beforeEach(^{
                        filter = mapping.eventFilters[2];
                    });
                    it(@"Should parse event type", ^{
                        [[theValue(filter.type) should] equal:theValue(AMAEventTypeECommerce)];
                    });
                    it(@"Revenue conditions should be nil", ^{
                        [[filter.revenueEventCondition should] beNil];
                    });
                    it(@"Client conditions should be nil", ^{
                        [[filter.clientEventCondition should] beNil];
                    });
                    it(@"Should parse ecom event condition", ^{
                        [[theValue([filter.eCommerceEventCondition checkEvent:AMAECommerceEventTypePurchase]) should] beYes];
                        [[AMAAttributionConvertingUtils should] receive:@selector(eCommerceTypeForString:error:) withArguments:@"purchase", kw_any()];
                        [parser parse:json];
                    });
                });
                context(@"Fourth event filter", ^{
                    AMAEventFilter *__block filter = nil;
                    beforeEach(^{
                        filter = mapping.eventFilters[3];
                    });
                    it(@"Should parse event type", ^{
                        [[theValue(filter.type) should] equal:theValue(AMAEventTypeClient)];
                    });
                    it(@"Revenue conditions should be nil", ^{
                        [[filter.revenueEventCondition should] beNil];
                    });
                    it(@"ECommerce conditions should be nil", ^{
                        [[filter.eCommerceEventCondition should] beNil];
                    });
                    it(@"Should parse client event condition", ^{
                        [[theValue([filter.clientEventCondition checkEvent:@"another name"]) should] beYes];
                    });
                });
            });
            context(@"Second mapping", ^{
                AMAAttributionMapping *__block mapping = nil;
                beforeEach(^{
                    mapping = config.conversion.mappings[1];
                });
                it(@"Should parse conversion value", ^{
                    [[theValue(mapping.conversionValueDiff) should] equal:theValue(4)];
                });
                it(@"Should parse required count", ^{
                    [[theValue(mapping.requiredCount) should] equal:theValue(1)];
                });
                it(@"Events size should be 1", ^{
                    [[theValue(mapping.eventFilters.count) should] equal:theValue(1)];
                });
                context(@"First event filter", ^{
                    AMAEventFilter *__block filter = nil;
                    beforeEach(^{
                        filter = mapping.eventFilters[0];
                    });
                    it(@"Should parse event type", ^{
                        [[theValue(filter.type) should] equal:theValue(AMAEventTypeClient)];
                    });
                    it(@"Revenue conditions should be nil", ^{
                        [[filter.revenueEventCondition should] beNil];
                    });
                    it(@"ECommerce conditions should be nil", ^{
                        [[filter.eCommerceEventCondition should] beNil];
                    });
                    it(@"Should parse client event condition", ^{
                        [[theValue([filter.clientEventCondition checkEvent:@"another mapping"]) should] beYes];
                    });
                });
            });
        });
    });
    context(@"Revenue", ^{
        AMAAttributionModelConfiguration *__block config = nil;
        NSDictionary *json = @{
            @"sending_stop_time_seconds" : @777888,
            @"max_saved_revenue_ids" : @56,
            @"model_type" : @"revenue",
            @"revenue_model": @{
                @"mapping": @[
                    @{
                        @"bound": @"1000",
                        @"value" : @67
                    },
                    @{
                        @"bound" : @"888",
                        @"value" : @89
                    }
                ],
                @"currency_rate" : @[
                    @{
                        @"code": @"USD",
                        @"amount" : @"1000000"
                    },
                    @{
                        @"code" : @"BYN",
                        @"amount" : @"2500000"
                    }
                ],
                @"events": @[
                    @{
                        @"event_type" : @"revenue",
                        @"revenue_events_conditions" : @{
                            @"source" : @"api"
                        }
                    },
                    @{
                        @"event_type" : @"ecom",
                        @"ecom_events_conditions" : @{
                            @"ecom_type" : @"purchase"
                        }
                    },
                ]
            }
        };
        beforeEach(^{
            config = [parser parse:json];
        });
        it(@"should not report error", ^{
            [[reporter shouldNot] receive:@selector(reportSKADAttributionParsingError:)];
            config = [parser parse:json];
        });
        it(@"Should parse stop time sending seconds", ^{
            [[config.stopSendingTimeSeconds should] equal:@777888];
        });
        it(@"Should parse max saved revenue ids", ^{
            [[config.maxSavedRevenueIDs should] equal:@56];
        });
        it(@"Max saved revenue ids should be default", ^{
            NSMutableDictionary *newJSON = [json mutableCopy];
            newJSON[@"max_saved_revenue_ids"] = nil;
            config = [parser parse:newJSON];
            [[config.maxSavedRevenueIDs should] equal:@50];
        });
        it(@"Should parse model type", ^{
            [[theValue(config.type) should] equal:theValue(AMAAttributionModelTypeRevenue)];
            [[AMAAttributionConvertingUtils should] receive:@selector(modelTypeForString:) withArguments:@"revenue"];
            [parser parse:json];
        });
        it(@"Conversion should be nil", ^{
            [[config.conversion should] beNil];
        });
        it(@"Engagement should be nil", ^{
            [[config.engagement should] beNil];
        });
        it(@"Revenue should not be nil", ^{
            [[config.revenue shouldNot] beNil];
        });
        context(@"Revenue", ^{
            it(@"Events size should be 2", ^{
                [[theValue(config.revenue.events.count) should] equal:theValue(2)];
            });
            it(@"Mappings size should be 2", ^{
                [[theValue(config.revenue.boundMappings.count) should] equal:theValue(2)];
            });
            context(@"First event", ^{
                AMAEventFilter *__block filter = nil;
                beforeEach(^{
                    filter = config.revenue.events[0];
                });
                it(@"Should parse event type", ^{
                    [[theValue(filter.type) should] equal:theValue(AMAEventTypeRevenue)];
                });
                it(@"Client conditions should be nil", ^{
                    [[filter.clientEventCondition should] beNil];
                });
                it(@"ECommerce conditions should be nil", ^{
                    [[filter.eCommerceEventCondition should] beNil];
                });
                it(@"Should parse revenue event condition", ^{
                    [[theValue([filter.revenueEventCondition checkEvent:NO]) should] beYes];
                    [[AMAAttributionConvertingUtils should] receive:@selector(revenueSourceForString:error:) withArguments:@"api", kw_any()];
                    [parser parse:json];
                });
            });
            context(@"Second event", ^{
                AMAEventFilter *__block filter = nil;
                beforeEach(^{
                    filter = config.revenue.events[1];
                });
                it(@"Should parse event type", ^{
                    [[theValue(filter.type) should] equal:theValue(AMAEventTypeECommerce)];
                });
                it(@"Client conditions should be nil", ^{
                    [[filter.clientEventCondition should] beNil];
                });
                it(@"Revenue conditions should be nil", ^{
                    [[filter.revenueEventCondition should] beNil];
                });
                it(@"Should parse ecom event condition", ^{
                    [[theValue([filter.eCommerceEventCondition checkEvent:AMAECommerceEventTypePurchase]) should] beYes];
                    [[AMAAttributionConvertingUtils should] receive:@selector(eCommerceTypeForString:error:) withArguments:@"purchase", kw_any()];
                    [parser parse:json];
                });
            });
            context(@"First mapping", ^{
                AMABoundMapping *__block mapping = nil;
                beforeEach(^{
                    mapping = config.revenue.boundMappings[0];
                });
                it(@"Should parse bound value", ^{
                    [[mapping.bound should] equal:[NSDecimalNumber decimalNumberWithString:@"888"]];
                });
                it(@"Should parse value", ^{
                    [[mapping.value should] equal:@89];
                });
            });
            context(@"Second mapping", ^{
                AMABoundMapping *__block mapping = nil;
                beforeEach(^{
                    mapping = config.revenue.boundMappings[1];
                });
                it(@"Should parse bound value", ^{
                    [[mapping.bound should] equal:[NSDecimalNumber decimalNumberWithString:@"1000"]];
                });
                it(@"Should parse value", ^{
                    [[mapping.value should] equal:@67];
                });
            });
            context(@"Currency rate", ^{
                AMACurrencyMapping *__block currencyMapping = nil;
                beforeEach(^{
                    currencyMapping = config.revenue.currencyMapping;
                });
                it(@"Should parse first rate", ^{
                    NSDecimalNumber *result = [currencyMapping convert:[NSDecimalNumber decimalNumberWithString:@"2"]
                                                              currency:@"USD"
                                                                 scale:1000000
                                                                 error:nil];
                    [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"2"]];
                });
                it(@"Should parse second rate", ^{
                    NSDecimalNumber *result = [currencyMapping convert:[NSDecimalNumber decimalNumberWithString:@"10"]
                                                              currency:@"BYN"
                                                                 scale:1000000
                                                                 error:nil];
                    [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"4"]];
                });
            });
        });
    });
    context(@"Invalid JSON", ^{
        AMAAttributionModelConfiguration *__block config = nil;
        it(@"No stop sending time seconds", ^{
            [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                @"error" : @"No stopSendingTimeSeconds"
            }];
            config = [parser parse:@{}];
            [[config should] beNil];
        });
        it(@"No model type", ^{
            [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                @"error" : @"Unknown attribution model type",
                @"input" : @"nil"
            }];
            config = [parser parse:@{ @"sending_stop_time_seconds" : @34 }];
            [[config should] beNil];
        });
        it(@"Unknown model type", ^{
            [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                @"error" : @"Unknown attribution model type",
                @"input" : @"unknown"
            }];
            config = [parser parse:@{ @"sending_stop_time_seconds" : @34, @"model_type" : @"unknown" }];
            [[config should] beNil];
        });
        context(@"Conversion", ^{
            it(@"No conversion model block", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"error" : @"No conversion config"
                }];
                config = [parser parse:@{ @"sending_stop_time_seconds" : @34, @"model_type" : @"conversion" }];
                [[config should] beNil];
            });
            it(@"No mapping", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"error" : @"No mapping",
                    @"model" : @"conversion_model"
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{}
                }];
                [[config should] beNil];
            });
            it(@"Empty mapping", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"error" : @"No mapping",
                    @"model" : @"conversion_model"
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No conversion value", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"No conversion value",
                        @"model" : @"conversion_model"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{}
                        ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No required count", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"No required count",
                        @"model" : @"conversion_model"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2
                            }
                        ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No events", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"No event filters"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1
                            }
                        ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"Empty events", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"No event filters"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[]
                            }
                        ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No event type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"Unknown event type",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{},
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"Unknown event type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"Unknown event type",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"unknown"
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No client event conditions", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"No client event conditions"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"client",
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No client event name", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"No client event name",
                        @"json" : @{}
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{}
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No revenue event conditions", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{ @"error" : @"No revenue event conditions" } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"revenue",
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No revenue source", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"Unknown revenue source",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"revenue",
                                        @"revenue_events_conditions" : @{}
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"Unknown revenue source", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"Unknown revenue source",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"revenue",
                                        @"revenue_events_conditions" : @{
                                            @"source" : @"unknown"
                                        }
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No ecom event conditions", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"No e-commerce event conditions"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"ecom",
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No ecom type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"Unknown e-commerce event type",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"ecom",
                                        @"ecom_events_conditions" : @{}
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"Unknown ecom type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[ @{
                        @"error" : @"Unknown e-commerce event type",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                    @{
                                        @"event_type" : @"ecom",
                                        @"ecom_events_conditions" : @{
                                            @"ecom_type" : @"unknown"
                                        }
                                    },
                                    @{
                                        @"event_type" : @"client",
                                        @"client_events_conditions" : @{
                                            @"event_name" : @"some name"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.conversion.mappings[0].eventFilters.count) should] equal:theValue(1)];
            });
            it(@"Several errors", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Conversion model errors" : @[
                        @{
                            @"error" : @"Unknown e-commerce event type",
                            @"value" : @"unknown"
                        },
                        @{
                            @"error" : @"Unknown event type",
                            @"value" : @"unknown"
                        },
                        @{
                            @"error" : @"No revenue event conditions"
                        },
                        @{
                            @"error" : @"No client event name",
                            @"json" : @{}
                        },
                        @{
                            @"error" : @"No conversion value",
                            @"model" : @"conversion_model"
                        }
                    ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"conversion",
                    @"conversion_model" : @{
                        @"mapping" : @[
                            @{
                                @"conversion_value" : @2,
                                @"required_count" : @1,
                                @"events" : @[
                                @{
                                    @"event_type" : @"ecom",
                                    @"ecom_events_conditions" : @{
                                       @"ecom_type" : @"unknown"
                                    }
                                },
                                @{
                                    @"event_type" : @"client",
                                    @"client_events_conditions" : @{
                                      @"event_name" : @"some name"
                                    }
                                },
                                @{
                                    @"event_type" : @"unknown"
                                },
                                @{
                                    @"event_type" : @"revenue"
                                },
                                @{
                                    @"event_type" : @"client",
                                    @"client_events_conditions" : @{}
                                }
                                ]
                            },
                            @{}
                        ]
                    }
                }];
                [[config shouldNot] beNil];
            });
        });
        context(@"Engagement", ^{
            it(@"No engagement model block", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"error" : @"No engagement config"
                }];
                config = [parser parse:@{ @"sending_stop_time_seconds" : @34, @"model_type" : @"engagement" }];
                [[config should] beNil];
            });
            it(@"No mapping", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model mappings errors" : @[ @{
                        @"error" : @"No mappings"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"events" : @[ @{
                            @"event_type" : @"client",
                            @"client_events_conditions" : @{
                                @"event_name" : @"some name"
                            }
                        } ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"Empty mapping", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model mappings errors" : @[ @{
                        @"error" : @"No mappings"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[],
                        @"events" : @[ @{
                            @"event_type" : @"client",
                            @"client_events_conditions" : @{
                                @"event_name" : @"some name"
                            }
                        } ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No bound", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model mappings errors" : @[ @{
                        @"error" : @"No bound in mapping",
                        @"json" : @{}
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{},
                            @{
                                @"bound" : @12,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[ @{
                            @"event_type" : @"client",
                            @"client_events_conditions" : @{
                                @"event_name" : @"some name"
                            }
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.boundMappings.count) should] equal:theValue(1)];
            });
            it(@"No value", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model mappings errors" : @[ @{
                        @"error" : @"No value in mapping",
                        @"json" : @{
                            @"bound" : @32
                        }
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32
                            },
                            @{
                                @"bound" : @12,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[ @{
                            @"event_type" : @"client",
                            @"client_events_conditions" : @{
                                @"event_name" : @"some name"
                            }
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.boundMappings.count) should] equal:theValue(1)];
            });
            it(@"No events", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"No event filters"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"Empty events", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"No event filters"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No event type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"Unknown event type",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{},
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"Unknown event type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"Unknown event type",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"unknown"
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No client event conditions", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"No client event conditions"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"client",
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No client event name", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"No client event name",
                        @"json" : @{}
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{}
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No revenue event conditions", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{ @"error" : @"No revenue event conditions" } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No revenue source", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"Unknown revenue source",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{}
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"Unknown revenue source", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"Unknown revenue source",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source" : @"unknown"
                                }
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No ecom event conditions", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"No e-commerce event conditions"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"ecom",
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"No ecom type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"Unknown e-commerce event type",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"ecom",
                                @"ecom_events_conditions" : @{}
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"Unknown ecom type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[ @{
                        @"error" : @"Unknown e-commerce event type",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"ecom",
                                @"ecom_events_conditions" : @{
                                    @"ecom_type" : @"unknown"
                                }
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.engagement.eventFilters.count) should] equal:theValue(1)];
            });
            it(@"Several mapping errors", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[
                        @{
                            @"error" : @"No value in mapping",
                            @"json" : @{ @"bound" : @42 }
                        },
                        @{
                            @"error" : @"No bound in mapping",
                            @"json" : @{}
                        }
                    ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            },
                            @{
                                @"bound" : @42
                            },
                            @{}
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
            });
            it(@"Several events errors", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Engagement model events errors" : @[
                        @{
                            @"error" : @"Unknown e-commerce event type",
                            @"value" : @"unknown"
                        },
                        @{
                            @"error" : @"Unknown event type",
                            @"value" : @"unknown"
                        },
                        @{
                            @"error" : @"No revenue event conditions"
                        },
                        @{
                            @"error" : @"No client event name",
                            @"json" : @{}
                        }
                    ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"engagement",
                    @"engagement_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @32,
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"ecom",
                                @"ecom_events_conditions" : @{
                                    @"ecom_type" : @"unknown"
                                }
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{
                                    @"event_name" : @"some name"
                                }
                            },
                            @{
                                @"event_type" : @"unknown"
                            },
                            @{
                                @"event_type" : @"revenue"
                            },
                            @{
                                @"event_type" : @"client",
                                @"client_events_conditions" : @{}
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
            });
        });
        context(@"Revenue", ^{
            it(@"No revenue model block", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"error" : @"No revenue config"
                }];
                config = [parser parse:@{ @"sending_stop_time_seconds" : @34, @"model_type" : @"revenue" }];
                [[config should] beNil];
            });
            it(@"No mapping", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model mappings errors" : @[ @{
                        @"error" : @"No mappings"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"events" : @[ @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source": @"api"
                            }
                        } ],
                        @"currency_rate" : @[ @{
                            @"code" : @"USD",
                            @"amount" : @"1000000"
                        } ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"Empty mapping", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model mappings errors" : @[ @{
                        @"error" : @"No mappings"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[],
                        @"events" : @[ @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source": @"api"
                            }
                        } ],
                        @"currency_rate" : @[ @{
                            @"code" : @"USD",
                            @"amount" : @"1000000"
                        } ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No bound", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model mappings errors" : @[ @{
                        @"error" : @"No bound in mapping",
                        @"json" : @{}
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{},
                            @{
                                @"bound" : @"12",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[ @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source": @"api"
                            }
                        } ],
                        @"currency_rate" : @[ @{
                            @"code" : @"USD",
                            @"amount" : @"1000000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.boundMappings.count) should] equal:theValue(1)];
            });
            it(@"No value", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model mappings errors" : @[ @{
                        @"error" : @"No value in mapping",
                        @"json" : @{
                            @"bound" : @"32"
                        }
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32"
                            },
                            @{
                                @"bound" : @"12",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[ @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source": @"api"
                            }
                        } ],
                        @"currency_rate" : @[ @{
                            @"code" : @"USD",
                            @"amount" : @"1000000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.boundMappings.count) should] equal:theValue(1)];
            });
            it(@"No currency_rate", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model currency errors" : @[ @{
                        @"error" : @"No currency mapping"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[ @{
                            @"bound" : @"12",
                            @"value" : @2
                        } ],
                        @"events" : @[ @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source": @"api"
                            }
                        } ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"Empty currency_rate", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model currency errors" : @[ @{
                        @"error" : @"No currency mapping"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[ @{
                            @"bound" : @"12",
                            @"value" : @2
                        } ],
                        @"events" : @[ @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source": @"api"
                            }
                        } ],
                        @"currency_rate" : @[]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No code", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model currency errors" : @[ @{
                        @"error" : @"No code in currency rate",
                        @"json" : @{}
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[ @{
                            @"bound" : @"12",
                            @"value" : @2
                        } ],
                        @"events" : @[ @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source": @"api"
                            }
                        } ],
                        @"currency_rate" : @[
                            @{},
                            @{
                                @"code" : @"BYN",
                                @"amount" : @"2500000"
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                AMACurrencyMapping *currencyMapping = config.revenue.currencyMapping;
                NSDecimalNumber *result = [currencyMapping convert:[NSDecimalNumber decimalNumberWithString:@"10"]
                                                          currency:@"BYN"
                                                            scale:1000000
                                                            error:nil];
                [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"4"]];
            });
            it(@"No amount", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model currency errors" : @[ @{
                        @"error" : @"Invalid amount in currency rate",
                        @"json" : @{
                            @"code" : @"USD"
                        }
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[ @{
                            @"bound" : @"12",
                            @"value" : @2
                        } ],
                        @"events" : @[ @{
                            @"event_type" : @"revenue",
                            @"revenue_events_conditions" : @{
                                @"source": @"api"
                            }
                        } ],
                        @"currency_rate" : @[
                            @{
                                @"code" : @"USD"
                            },
                            @{
                                @"code" : @"BYN",
                                @"amount" : @"2500000"
                            }
                        ]
                    }
                }];
                [[config shouldNot] beNil];
                AMACurrencyMapping *currencyMapping = config.revenue.currencyMapping;
                NSDecimalNumber *result = [currencyMapping convert:[NSDecimalNumber decimalNumberWithString:@"10"]
                                                          currency:@"BYN"
                                                             scale:1000000
                                                             error:nil];
                [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"4"]];
            });
            it(@"No events", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"No event filters"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"Empty events", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"No event filters"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config should] beNil];
            });
            it(@"No event type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"Unknown event type",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{},
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source": @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"Unknown event type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"Unknown event type",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"unknown"
                            },
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source": @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"Client event type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"Unknown event type",
                        @"value" : @"client"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"client"
                            },
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source": @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"No revenue event conditions", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"No revenue event conditions"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                            },
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source": @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"No revenue source", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"Unknown revenue source",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{}
                            },
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source": @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"Unknown revenue source", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"Unknown revenue source",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source" : @"unknown"
                                }
                            },
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source": @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"No ecom event conditions", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"No e-commerce event conditions"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"ecom",
                            },
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source": @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"No ecom type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"Unknown e-commerce event type",
                        @"value" : @"nil"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"ecom",
                                @"ecom_events_conditions" : @{}
                            },
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source" : @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"Unknown ecom type", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[ @{
                        @"error" : @"Unknown e-commerce event type",
                        @"value" : @"unknown"
                    } ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"ecom",
                                @"ecom_events_conditions" : @{
                                    @"ecom_type" : @"unknown"
                                }
                            },
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source" : @"api"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
                [[config shouldNot] beNil];
                [[theValue(config.revenue.events.count) should] equal:theValue(1)];
            });
            it(@"Several errors in events", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model events errors" : @[
                        @{
                            @"error" : @"Unknown event type",
                            @"value" : @"unknown"
                        },
                        @{
                            @"error" : @"No revenue event conditions"
                        },
                        @{
                            @"error" : @"Unknown e-commerce event type",
                            @"value" : @"unknown"
                        }
                    ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                    @"source" : @"api"
                                }
                            },
                            @{
                                @"event_type" : @"unknown"
                            },
                            @{
                                @"event_type" : @"revenue"
                            },
                            @{
                                @"event_type" : @"ecom",
                                @"ecom_events_conditions" : @{
                                    @"ecom_type" : @"unknown"
                                }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
            });
            it(@"Several errors in currency", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model currency errors" : @[
                        @{
                            @"error" : @"Invalid amount in currency rate",
                            @"json" : @{ @"code" : @"USD" }
                        },
                        @{
                            @"error" : @"No code in currency rate",
                            @"json" : @{}
                        }
                    ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            }
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                @"source" : @"api"
                            }
                            }
                        ],
                        @"currency_rate" : @[
                            @{
                                @"code" : @"BYN",
                                @"amount" : @"2500000"
                            },
                            @{
                                @"code" : @"USD"
                            },
                            @{}
                        ]
                    }
                }];
            });
            it(@"Several errors in mapping", ^{
                [[reporter should] receive:@selector(reportSKADAttributionParsingError:) withArguments: @{
                    @"Revenue model mappings errors" : @[
                        @{
                            @"error" : @"No value in mapping",
                            @"json" : @{ @"bound" : @"42" }
                        },
                        @{
                            @"error" : @"No bound in mapping",
                            @"json" : @{}
                        }
                    ]
                }];
                config = [parser parse:@{
                    @"sending_stop_time_seconds" : @34,
                    @"model_type" : @"revenue",
                    @"revenue_model" : @{
                        @"mapping" : @[
                            @{
                                @"bound" : @"32",
                                @"value" : @2
                            },
                            @{
                                @"bound" : @"42"
                            },
                            @{}
                        ],
                        @"events" : @[
                            @{
                                @"event_type" : @"revenue",
                                @"revenue_events_conditions" : @{
                                @"source" : @"api"
                            }
                            }
                        ],
                        @"currency_rate" : @[ @{
                            @"code" : @"BYN",
                            @"amount" : @"2500000"
                        } ]
                    }
                }];
            });
        });
    });
});

SPEC_END
