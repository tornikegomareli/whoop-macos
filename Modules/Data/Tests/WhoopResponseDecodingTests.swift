import Foundation
import Testing
@testable import WhoopScopeData

@Test
func responseDecoderReadsWHOOPSnakeCaseAndDates() throws {
    let profileData = Data(
        """
        {
          "user_id": 42,
          "email": "member@example.com",
          "first_name": "Member",
          "last_name": "Example"
        }
        """.utf8
    )
    let cycleData = Data(
        """
        {
          "records": [{
            "id": 10,
            "user_id": 42,
            "created_at": "2026-07-12T06:00:00.000Z",
            "updated_at": "2026-07-12T06:01:00Z",
            "start": "2026-07-12T06:00:00.000Z",
            "end": null,
            "timezone_offset": "+04:00",
            "score_state": "PENDING_SCORE",
            "score": null
          }],
          "next_token": "next-page"
        }
        """.utf8
    )

    let profile = try WhoopAPIClient.makeResponseDecoder().decode(
        WhoopUserProfileDTO.self,
        from: profileData
    )
    let page = try WhoopAPIClient.makeResponseDecoder().decode(
        WhoopPage<WhoopCycleDTO>.self,
        from: cycleData
    )

    #expect(profile.userID == 42)
    #expect(profile.firstName == "Member")
    #expect(page.records.count == 1)
    #expect(page.records[0].userId == 42)
    #expect(page.nextToken == "next-page")
}
