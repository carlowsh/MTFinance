# MTFinance - Salesforce Loan Management Solution

## Description

This repository contains the custom Apex logic and triggers required to manage a loan portfolio within Salesforce. It includes:

- Custom App and Lightning Pages for `Loand` & `Loan__Charge` 
- Custom trigger and handler for `Loan__c`
- Custom trigger and handler for `Loan_Charge__c`
- Custom handlers for both triggers
- Apex test classes with over 85% code coverage
- Apex Constants label control 

* Loan Management works with Person Accounts; therefore, you need to configure and activate them in your environment. 

---

## Deployment Instructions

### Prerequisites

- Salesforce CLI installed: https://developer.salesforce.com/tools/sfdxcli
- A Salesforce Developer Edition org: https://developer.salesforce.com/signup
- Git installed

### Steps


1. Clone this repository:
```bash
git clone https://github.com/carlowsh/MTFinance.git
cd MTFinance/mtfinance


2. Authenticate to your Salesforce org

sfdx auth:web:login -a DevOrg

3. Deploy the source code to the org
sfdx force:source:deploy -p force-app -u DevOrg


4. Run all Apex tests
sfdx force:apex:test:run -u DevOrg -c -r human

##########

Post-Deployment Verification
After deployment:

Go to Object Manager > Loan__c

Confirm custom fields like Term__c, Balance_of_the_Loan__c exist

Go to Apex Classes and confirm:

LoanTriggerHandler, LoanChargeHandler, and their test classes are present

Check Triggers:

LoanTrigger, LoanChargeTrigger should be active

Run Test Classes via Setup > Apex Test Execution to confirm coverage
