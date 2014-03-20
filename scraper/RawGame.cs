using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Globalization;

namespace YahooSportsStatsScraper
{
    /// <summary>
    /// Contains a Game's ID, the team IDs, the date of the game, and the scores
    /// </summary>
    class RawGame
    {
        public static Dictionary<string, string> teamToId = new Dictionary<string, string>();

        public string GameID;
        public string GameUrl;
        public string HomeTeamYahooID;
        public string VisitingTeamYahooID;
        public DateTime GameDate;
        public string GameTime;
        public int HomeScore;
        public int VisitingScore;
        public bool Played;

        public RawGame(string gameID, string gameUrl, string homeTeam, string visitingTeam, string gameDate, int homeScore, int visitingScore)
        {
            this.GameID = gameID;
            this.GameUrl = gameUrl;

            if (teamToId.ContainsKey(homeTeam))
            {
                this.HomeTeamYahooID = teamToId[homeTeam];
            }
            else
            {
                this.HomeTeamYahooID = DatabaseHelper.getTeamId(homeTeam.Trim());
                teamToId[homeTeam] = this.HomeTeamYahooID;
            }

            if (teamToId.ContainsKey(visitingTeam))
            {
                this.VisitingTeamYahooID = teamToId[visitingTeam];
            }
            else
            {
                this.VisitingTeamYahooID = DatabaseHelper.getTeamId(visitingTeam.Trim());
                teamToId[visitingTeam] = this.VisitingTeamYahooID;
            }
            
            try
            {
                this.GameDate = DateTime.ParseExact(gameDate, "yyyyMMdd", CultureInfo.InvariantCulture);
            }
            catch
            {
                try
                {
                    this.GameDate = DateTime.Parse(gameDate);
                }
                catch
                {
                    try
                    {
                        string newGameDate = String.Format("{0}, {1}", gameDate, DateTime.Now.Year - 1);
                        this.GameDate = DateTime.Parse(newGameDate);
                    }
                    catch (FormatException e)
                    {
                        Console.WriteLine("Unable to parse DateTime from string \"{0}\": {1}", gameDate, e.Message);
                    }
                }
            }
            this.HomeScore = homeScore;
            this.VisitingScore = visitingScore;
            this.Played = true;
        }

        public RawGame(string homeTeam, string visitingTeam, string gameDate, string gameTime)
        {
            this.HomeTeamYahooID = homeTeam;
            this.VisitingTeamYahooID = visitingTeam;
            bool isGameEarlySeason = gameDate.Contains("Dec") || gameDate.Contains("Nov");
            bool isNowEarlySeason = DateTime.Today.Month > 10;
            int gameYear = DateTime.Today.Year;
            if (isGameEarlySeason && !isNowEarlySeason)
            {
                gameYear--;
            }
            if (!isGameEarlySeason && isNowEarlySeason)
            {
                gameYear++;
            }
            if (!gameTime.EndsWith("pm", StringComparison.CurrentCultureIgnoreCase) && !gameTime.EndsWith("am", StringComparison.CurrentCultureIgnoreCase))
            {
                gameTime = "";
            }
            string dateFormat = String.Format("{0}, {1} {2}", gameDate, gameYear, gameTime);
            this.GameDate = DateTime.Parse(dateFormat);
            this.GameTime = gameTime;
            this.Played = false;
        }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            sb.Append('(');
            if (Played)
            {
                sb.Append('"' + GameID + '"');
                sb.Append(',');
                sb.Append('"' + GameUrl + '"');
                sb.Append(',');
                sb.Append('"' + HomeTeamYahooID + '"');
                sb.Append(',');
                sb.Append('"' + VisitingTeamYahooID + '"');
                sb.Append(',');
                sb.Append('"' + GameDate.ToString("yyyy-MM-dd") + '"');
                sb.Append(',');
                sb.Append(HomeScore);
                sb.Append(',');
                sb.Append(VisitingScore);
            }
            else
            {
                sb.Append('"' + HomeTeamYahooID + '"');
                sb.Append(',');
                sb.Append('"' + VisitingTeamYahooID + '"');
                sb.Append(',');
                sb.Append('"' + GameDate.ToString("yyyy-MM-dd HH:mm:ss") + '"');
            }
            sb.Append(')');
            return sb.ToString();
        }

        /// <summary>
        /// Gets the insert statement for adding RawGame objects that have already been played
        /// </summary>
        /// <returns></returns>
        public static string GetGamesInsertStatement()
        {
            return "INSERT INTO tblgames (gameID, yahooGameUrl, homeTeamYahooID, visitingTeamYahooID, date, homeScore, visitingScore) VALUES ";
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public static string GetGamesInsertStatementEnd()
        {
            return " ON DUPLICATE KEY UPDATE yahooGameUrl=values(yahooGameUrl), homeTeamYahooID=values(homeTeamYahooID), visitingTeamYahooID=values(visitingTeamYahooID), date=values(date), homeScore=values(homeScore), visitingScore=values(visitingScore)";
        }

        /// <summary>
        /// Gets the insert statement for adding RawGame objects that have yet to be played
        /// </summary>
        /// <returns></returns>
        public static string GetScheduleInsertStatement()
        {
            return "INSERT IGNORE INTO tblschedule (homeTeam, awayTeam, Date) VALUES ";
        }
    }

}
