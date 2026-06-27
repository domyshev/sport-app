import Testing
@testable import SportApp

struct WeeklyEffortChartInteractionPolicyTests {
    @Test func scrollFirstPolicyDoesNotAttachCanvasDragSelection() {
        #expect(!WeeklyEffortChartInteractionPolicy.scrollFirst.allowsCanvasDragSelection)
    }
}
