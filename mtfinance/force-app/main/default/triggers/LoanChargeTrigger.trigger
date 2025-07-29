trigger LoanChargeTrigger on Loan_Charge__c (before insert, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        LoanChargeHandler.preventDuplicateReleaseCharges(Trigger.new);
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LoanChargeHandler.handleNewCharge(Trigger.new);
        }
        if (Trigger.isUpdate) {
            LoanChargeHandler.recalculateLoanBalances(Trigger.new);
        }
    }
}