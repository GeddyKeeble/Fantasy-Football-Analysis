**Sleeper League Data Tool**
This project provides a single Power Query (M) script that pulls all matchup and manager data from a Sleeper Fantasy Football league into Excel or Power BI. It combines user, roster, and weekly matchup data into one flat table.

**Setup Instructions**
1. Open the file Sleeper_League_Data.m in this repository and copy the code.
2. In Excel or Power BI, create a new Blank Query.
3. Open the Advanced Editor and paste the code, replacing everything currently there.
4. Locate the TargetLeagueID variable at the top of the script and enter your specific League ID between the quotation marks.
5. Click Done and then Close & Load.

**How to Find Your League ID**
Your League ID is the numeric string found in your browser's address bar when you are viewing your league on Sleeper.com.

Example: https://sleeper.com/leagues/1257478461895753728/ The ID in this case is 1257478461895753728.

**Data Included**
The resulting table includes:
- Weekly matchup results (Weeks 1-15/17)
- Manager display names
- Opponent names
- Player names, positions, and NFL teams
- Starter and Bench designations
