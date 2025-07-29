public class LoanChargeHandler {

    public static void preventDuplicateReleaseCharges(List<Loan_Charge__c> newCharges) {
        Set<Id> loanIds = new Set<Id>();

        for (Loan_Charge__c charge : newCharges) {
            if (charge.Charge_Type__c == Constants.RELEASE_CHARGE && charge.Loan__c != null) {
                loanIds.add(charge.Loan__c);
            }
        }

        if (!loanIds.isEmpty()) {
            Map<Id, Integer> existing = new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT Loan__c loanId, COUNT(Id) cnt FROM Loan_Charge__c WHERE Loan__c IN :loanIds AND Charge_Type__c =: Constants.RELEASE_CHARGE GROUP BY Loan__c]) {
                
				existing.put((Id)result.get('loanId'), (Integer)result.get('cnt'));
            }

            for (Loan_Charge__c charge : newCharges) {
                if (charge.Charge_Type__c == Constants.RELEASE_CHARGE &&
                    existing.containsKey(charge.Loan__c)) {
                    charge.addError('Only one Release Charge is allowed per Loan.');
                }
            }
        }
    }

    public static void handleNewCharge(List<Loan_Charge__c> charges) {
        Set<Id> loanIds = new Set<Id>();

        for (Loan_Charge__c c : charges) {
            if (c.Loan__c != null) {
                loanIds.add(c.Loan__c);
            }
        }

        if (loanIds.isEmpty()) return;

        Map<Id, Loan_Charge__c> releaseCharges = new Map<Id, Loan_Charge__c>();

        for (Loan_Charge__c rc : [
            SELECT Id, Loan__c, Charge_Date__c  
            FROM Loan_Charge__c 
            WHERE Charge_Type__c =: Constants.RELEASE_CHARGE AND Loan__c IN :loanIds
        ]) {
            releaseCharges.put(rc.Loan__c, rc);
        }

        List<Loan_Charge__c> updates = new List<Loan_Charge__c>();
        Set<Id> updatedReleaseIds = new Set<Id>();

        for (Loan_Charge__c charge : charges) {
            if (charge.Charge_Type__c != Constants.RELEASE_CHARGE) {
                Loan_Charge__c release = releaseCharges.get(charge.Loan__c);

                if (release != null &&
                    charge.Charge_Date__c != null &&
                    charge.Charge_Date__c >= release.Charge_Date__c &&
                    !updatedReleaseIds.contains(release.Id)) {
                    
                    release.Charge_Date__c = release.Charge_Date__c.addMonths(1);
                    updates.add(release);
                    updatedReleaseIds.add(release.Id);
                }
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }

        recalculateLoanBalances(charges);
    }

    public static void recalculateLoanBalances(List<Loan_Charge__c> charges) {
        Set<Id> loanIds = new Set<Id>();
        for (Loan_Charge__c c : charges) {
            if (c.Loan__c != null) {
                loanIds.add(c.Loan__c);
            }
        }

        if (loanIds.isEmpty()) return;

        Map<Id, Decimal> totalCharges = new Map<Id, Decimal>();

        for (AggregateResult result : [
            SELECT Loan__c, SUM(Amount__c) total
            FROM Loan_Charge__c
            WHERE Loan__c IN :loanIds
            GROUP BY Loan__c
        ]) {
            totalCharges.put((Id)result.get('Loan__c'), (Decimal)result.get('total'));
        }

        List<Loan__c> updates = new List<Loan__c>();

        for (Loan__c loan : [
            SELECT Id, Gross_Loan_Amount__c FROM Loan__c WHERE Id IN :loanIds
        ]) {
            Decimal chargesSum = totalCharges.get(loan.Id);
            loan.Balance_of_the_Loan__c = loan.Gross_Loan_Amount__c + (chargesSum != null ? chargesSum : 0);
            loan.Total_Charges_on_the_Loan__c = (chargesSum != null ? chargesSum : 0);
            updates.add(loan);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}