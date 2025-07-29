@isTest
private class LoanTriggerHandlerTest {

	private static Decimal getExpectedTotal(List<Decimal> charges) {
        Decimal total = 0;
        for (Decimal charge : charges) {
            total += charge;
        }
        return total;
    }

    @testSetup
    static void setupTestData() {
        Account acc = new Account(
            LastName = 'Test User',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1].Id
        );
        insert acc;

        Loan__c loan = new Loan__c(
            Name = 'Test Loan',
            Account__c = acc.Id,
            Address__c = '123 Test St',
            Date_Loan_Issued__c = Date.today(),
            Term__c = 6,
            Gross_Loan_Amount__c = 10000
        );
        insert loan;
    }

    @isTest
    static void testLoanInsertCreatesReleaseCharge() {
        Loan__c loan = [SELECT Id FROM Loan__c LIMIT 1];

        List<Loan_Charge__c> charges = [
            SELECT Id, Charge_Type__c, Charge_Date__c 
            FROM Loan_Charge__c 
            WHERE Loan__c = :loan.Id
        ];

        System.assertEquals(1, charges.size(), 'Should have 1 Release Charge');
        System.assertEquals('Release Charge', charges[0].Charge_Type__c);
        System.assertEquals(Date.today().addMonths(6), charges[0].Charge_Date__c);
    }

    @isTest
    static void testPreventDuplicateReleaseCharge() {
        Loan__c loan = [SELECT Id FROM Loan__c LIMIT 1];

        Loan_Charge__c duplicate = new Loan_Charge__c(
            Loan__c = loan.Id,
            Charge_Type__c = 'Release Charge',
            Amount__c = 500,
            Charge_Date__c = Date.today().addMonths(6)
        );

        Test.startTest();
        try {
            insert duplicate;
            System.assert(false, 'Should have thrown error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Only one Release Charge'), 'Expected duplicate validation');
        }
        Test.stopTest();
    }

    @isTest
    static void testLoanUpdateChangesReleaseDateAndAddsAdminFee() {
        Loan__c loan = [SELECT Id, Term__c FROM Loan__c LIMIT 1];
        loan.Term__c = 12;

        Test.startTest();
        update loan;
        Test.stopTest();

        List<Loan_Charge__c> charges = [
            SELECT Charge_Type__c, Charge_Date__c 
            FROM Loan_Charge__c 
            WHERE Loan__c = :loan.Id
        ];

        Integer releaseCount = 0;
        Boolean releaseUpdated = false;
        Boolean adminFeeFound = false;

        for (Loan_Charge__c c : charges) {
            if (c.Charge_Type__c == 'Release Charge') {
                releaseCount++;
                if (c.Charge_Date__c == Date.today().addMonths(12)) {
                    releaseUpdated = true;
                }
            }
            if (c.Charge_Type__c == 'Admin Fee') {
                adminFeeFound = true;
                System.assertEquals(Date.today(), c.Charge_Date__c, 'Admin Fee date should be today');
            }
        }

        System.assertEquals(1, releaseCount, 'Should still be only one Release Charge');
        System.assert(releaseUpdated, 'Release Charge should be updated to new term');
        System.assert(adminFeeFound, 'Admin Fee should be created');
    }

    @isTest
    static void testChargeAfterReleaseExtendsDate() {
        Loan__c loan = [SELECT Id FROM Loan__c LIMIT 1];
        Date originalRelease = Date.today().addMonths(6);

        Loan_Charge__c extraCharge = new Loan_Charge__c(
            Loan__c = loan.Id,
            Charge_Type__c = 'Interest Charge',
            Amount__c = 250,
            Charge_Date__c = originalRelease
        );

        Test.startTest();
        insert extraCharge;
        Test.stopTest();

        Loan_Charge__c updatedRelease = [
            SELECT Charge_Date__c 
            FROM Loan_Charge__c 
            WHERE Loan__c = :loan.Id AND Charge_Type__c = 'Release Charge'
            LIMIT 1
        ];

        System.assertEquals(originalRelease.addMonths(1), updatedRelease.Charge_Date__c,
            'Release Charge should be moved 1 month forward');
    }

    @isTest
    static void testBalanceAndTotalChargesCalculation() {
        Loan__c loan = [SELECT Id, Gross_Loan_Amount__c FROM Loan__c LIMIT 1];

        insert new List<Loan_Charge__c>{
            new Loan_Charge__c(
                Loan__c = loan.Id,
                Charge_Type__c = 'Interest Charge',
                Amount__c = 200,
                Charge_Date__c = Date.today()
            ),
            new Loan_Charge__c(
                Loan__c = loan.Id,
                Charge_Type__c = 'Legal Fee',
                Amount__c = 300,
                Charge_Date__c = Date.today()
            )
        };

        Loan__c updatedLoan = [
            SELECT Balance_of_the_Loan__c, Total_Charges_on_the_Loan__c 
            FROM Loan__c 
            WHERE Id = :loan.Id
        ];

        Decimal expectedCharges = getExpectedTotal(new List<Decimal>{500, 200, 300});
        Decimal expectedBalance = loan.Gross_Loan_Amount__c + expectedCharges;
        
        System.assertEquals(expectedBalance, updatedLoan.Balance_of_the_Loan__c);
        System.assertEquals(expectedCharges, updatedLoan.Total_Charges_on_the_Loan__c);
    }
}