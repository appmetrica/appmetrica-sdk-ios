
#if __has_include("AppMetricaTestUtils.h")
    #import "CLLocation+TestUtilities.h"
    #import "AMADateProviderMock.h"
    #import "AMALocaleMock.h"
    #import "AMAModuleBundleProvider.h"
    #import "AMAMutableSKPaymentTransaction.h"
    #import "AMAMutableSKProduct.h"
    #import "AMATestAssertionHandler.h"
    #import "AMATestExecutor.h"
    #import "AMATestSafeTransactionRollbackContext.h"
    #import "AMATestTruncator.h"
    #import "AMATestURLProtocol.h"
    #import "AMATestUtilities.h"
    #import "AMAUserDefaultsMock.h"
#else
    #import <AppMetricaTestUtils/CLLocation+TestUtilities.h>
    #import <AppMetricaTestUtils/AMADateProviderMock.h>
    #import <AppMetricaTestUtils/AMALocaleMock.h>
    #import <AppMetricaTestUtils/AMAModuleBundleProvider.h>
    #import <AppMetricaTestUtils/AMAMutableSKPaymentTransaction.h>
    #import <AppMetricaTestUtils/AMAMutableSKProduct.h>
    #import <AppMetricaTestUtils/AMATestAssertionHandler.h>
    #import <AppMetricaTestUtils/AMATestExecutor.h>
    #import <AppMetricaTestUtils/AMATestSafeTransactionRollbackContext.h>
    #import <AppMetricaTestUtils/AMATestTruncator.h>
    #import <AppMetricaTestUtils/AMATestURLProtocol.h>
    #import <AppMetricaTestUtils/AMATestUtilities.h>
    #import <AppMetricaTestUtils/AMAUserDefaultsMock.h>
#endif
