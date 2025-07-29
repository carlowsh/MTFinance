public class LoanTriggerHandler {

    public static void handleLoanInsert(List<Loan__c> newLoans) {
        List<Loan_Charge__c> releaseCharges = new List<Loan_Charge__c>();

        for (Loan__c loan : newLoans) {
            if (loan.Date_Loan_Issued__c != null && loan.Term__c != null) {
                Date releaseDate = loan.Date_Loan_Issued__c.addMonths((Integer)loan.Term__c);

                releaseCharges.add(new Loan_Charge__c(
                    Loan__c = loan.Id,
                    Charge_Type__c = Constants.RELEASE_CHARGE,
                    Amount__c = 500,
                    Charge_Date__c = releaseDate
                ));
            }
        }

        if (!releaseCharges.isEmpty()) {
            insert releaseCharges;
        }
    }

    public static void handleLoanUpdate(List<Loan__c> newLoans, Map<Id, Loan__c> oldMap) {
        List<Loan_Charge__c> updates = new List<Loan_Charge__c>();
        List<Loan_Charge__c> adminFees = new List<Loan_Charge__c>();

        Set<Id> loanIds = new Set<Id>();

        for (Loan__c loan : newLoans) {
            Loan__c oldLoan = oldMap.get(loan.Id);

            if (loan.Term__c != oldLoan.Term__c && loan.Term__c != null && loan.Date_Loan_Issued__c != null) {
                loanIds.add(loan.Id);
            }
        }

        if (loanIds.isEmpty()) return;

        Map<Id, Loan_Charge__c> releaseChargeMap = new Map<Id, Loan_Charge__c>();

        for (Loan_Charge__c rc : [
            SELECT Id, Loan__c, Charge_Date__c 
            FROM Loan_Charge__c 
            WHERE Charge_Type__c =: Constants.RELEASE_CHARGE AND Loan__c IN :loanIds
        ]) {
            releaseChargeMap.put(rc.Loan__c, rc);
        }

        for (Loan__c loan : newLoans) {
            Loan__c oldLoan = oldMap.get(loan.Id);

            if (loan.Term__c != oldLoan.Term__c && loan.Term__c != null && loan.Date_Loan_Issued__c != null) {
                Date newReleaseDate = loan.Date_Loan_Issued__c.addMonths((Integer)loan.Term__c);

                Loan_Charge__c release = releaseChargeMap.get(loan.Id);

                if (release != null) {
                    release.Charge_Date__c = newReleaseDate;
                    updates.add(release);
                }

                adminFees.add(new Loan_Charge__c(
                    Loan__c = loan.Id,
                    Charge_Type__c = Constants.ADMIN_FEE,
                    Amount__c = 300,
                    Charge_Date__c = Date.today()
                ));
            }
        }

        if (!updates.isEmpty()) update updates;
        if (!adminFees.isEmpty()) insert adminFees;
    }
}