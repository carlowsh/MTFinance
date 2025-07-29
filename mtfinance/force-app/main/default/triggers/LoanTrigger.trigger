trigger LoanTrigger on Loan__c (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LoanTriggerHandler.handleLoanInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            LoanTriggerHandler.handleLoanUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}