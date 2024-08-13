global class ScheduleDeleteIntegrationQuotes implements schedulable
{
    global void execute(SchedulableContext sc){
        DeleteIntegrationQuotes b = new DeleteIntegrationQuotes();
        database.executebatch(b);
    }
}