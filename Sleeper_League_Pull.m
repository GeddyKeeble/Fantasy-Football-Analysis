let
    // ==========================================
    // USER INPUT: Enter your Sleeper League ID below
    // ==========================================
    TargetLeagueID = "1257478461895753728", 
    
    // 1. Fetch Manager Names
    UsersUrl = "https://api.sleeper.app/v1/league/" & TargetLeagueID & "/users",
    Users = Json.Document(Web.Contents(UsersUrl)),
    UserTable = Table.FromList(Users, Splitter.SplitByNothing()),
    UserFields = Table.ExpandRecordColumn(UserTable, "Column1", {"user_id", "display_name"}),

    // 2. Fetch Rosters (to link Manager to RosterID)
    RosterUrl = "https://api.sleeper.app/v1/league/" & TargetLeagueID & "/rosters",
    Rosters = Json.Document(Web.Contents(RosterUrl)),
    RosterTable = Table.FromList(Rosters, Splitter.SplitByNothing()),
    RosterFields = Table.ExpandRecordColumn(RosterTable, "Column1", {"roster_id", "owner_id"}),
    ManagerLookup = Table.Join(RosterFields, "owner_id", UserFields, "user_id"),

    // 3. Get Weekly Matchups (Weeks 1-15)
    WeeklyMatchups = List.Transform({1..15}, (wk) => 
        let
            MUrl = "https://api.sleeper.app/v1/league/" & TargetLeagueID & "/matchups/" & Text.From(wk),
            MData = Json.Document(Web.Contents(MUrl)),
            MTable = Table.FromList(MData, Splitter.SplitByNothing()),
            MExpand = Table.ExpandRecordColumn(MTable, "Column1", {"matchup_id", "roster_id", "players_points", "starters"}),
            
            // Join Manager Names
            AddManagers = Table.Join(MExpand, "roster_id", ManagerLookup, "roster_id"),
            
            // Create Opponent Mapping
            Opponents = Table.RenameColumns(Table.SelectColumns(AddManagers, {"matchup_id", "display_name"}), {{"display_name", "Opponent"}}),
            MatchupWithOpp = Table.NestedJoin(AddManagers, {"matchup_id"}, Opponents, {"matchup_id"}, "Temp", JoinKind.LeftOuter),
            ExpandedOpp = Table.ExpandTableColumn(MatchupWithOpp, "Temp", {"Opponent"}),
            FilterSelf = Table.SelectRows(ExpandedOpp, each [display_name] <> [Opponent]),

            // Extract Player Data
            ExtractPlayers = Table.AddColumn(FilterSelf, "Players", each 
                let 
                    PointsRec = [players_points],
                    PIDs = if PointsRec <> null then Record.FieldNames(PointsRec) else {}
                in 
                    List.Transform(PIDs, (id) => [
                        PlayerID = id, 
                        Points = Record.Field(PointsRec, id),
                        LineupStatus = if List.Contains([starters], id) then "Starter" else "Bench"
                    ])
            ),
            FinalExpand = Table.ExpandListColumn(ExtractPlayers, "Players"),
            FinalFields = Table.ExpandRecordColumn(FinalExpand, "Players", {"PlayerID", "Points", "LineupStatus"}),
            AddWeek = Table.AddColumn(FinalFields, "Week", each wk)
        in
            AddWeek
    ),
    CombinedWeeks = Table.Combine(WeeklyMatchups),

    // 4. Merge with SleeperPlayers (Assumes you have a query named 'SleeperPlayers')
    #"Merge Player Names" = Table.NestedJoin(CombinedWeeks, {"PlayerID"}, SleeperPlayers, {"PlayerID"}, "PD", JoinKind.LeftOuter),
    #"Expand Player Details" = Table.ExpandTableColumn(#"Merge Player Names", "PD", {"Full Name", "Position", "NFL Team"}),
    
    // 5. Final Formatting
    #"Clean Team Names" = Table.AddColumn(#"Expand Player Details", "Final NFL Team", each if [NFL Team] <> null then [NFL Team] else if Text.Length([PlayerID]) <= 3 then [PlayerID] else "N/A"),
    #"Set Data Types" = Table.TransformColumnTypes(#"Clean Team Names",{{"Points", type number}, {"Week", Int64.Type}})
in
    #"Set Data Types"
