
#import "AMATransactionInfoModel.h"

@interface AMATransactionInfoMutableModel : AMATransactionInfoModel

@property (nonatomic, strong) NSString *transactionID;
@property (nonatomic, strong) NSDate *transactionTime;
@property (nonatomic, assign) AMATransactionState transactionState;
@property (nonatomic, strong) NSString *secondaryID;
@property (nonatomic, strong) NSDate *secondaryTime;

@end
