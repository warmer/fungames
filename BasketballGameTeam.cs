using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace YahooSportsStatsScraper
{
    class BasketballGameTeam
    {
        List<BasketballGamePlayer> TeamPlayers = new List<BasketballGamePlayer>();

        public string Gid;
        public string TeamID;
        public DateTime GameDate;
        public int Score;
        public bool IsHome;

        public bool StatsAreValid = false;
        public bool OffValid = false;
        public bool RebValid = false;
        public bool AstValid = false;
        public bool TOValid = false;
        public bool BlkValid = false;

        /// <summary>
        /// Populates this object with the known game ID and the team
        /// </summary>
        /// <param name="gid"></param>
        /// <param name="teamID"></param>
        public BasketballGameTeam(string gid, string teamID, DateTime gameDate, int score, bool isHome)
        {
            Gid = gid;
            TeamID = teamID;
            GameDate = gameDate;
            Score = score;
            IsHome = isHome;

            var playerForThisTeamAndGame = from b in Program.allPlayerStats
                                           where b.Gid == gid && b.TeamID == teamID
                                           select b;
            foreach (BasketballGamePlayer b in playerForThisTeamAndGame)
            {
                TeamPlayers.Add(b);
            }
            int scoreSum = TeamPlayers.Sum(b => b.Pts);
            // are these stats valid?
            if (scoreSum != score)
            {
                Console.WriteLine("Sum: {0}; Actual: {1}; game {2} team {3}", scoreSum, score, gid, teamID);
            }
            else
            {
                StatsAreValid = true;
            }
        }
    }

}
