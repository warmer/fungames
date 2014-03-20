using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BasketballGamePrediction
{
    class Game
    {
        public string getGameQuery = "SELECT gameID, homeTeamYahooID, visitingTeamYahooID, date, homeScore, visitingScore FROM tblgames ORDER BY gameID DESC";
        public long GameID { get; set; }
        public string HomeTeam { get; set; }
        public string AwayTeam { get; set; }
        public DateTime Date { get; set; }
        public int HomeScore { get; set; }
        public int AwayScore { get; set; }
        public float PredictedHomeScore { get; set; }
        public float PredictedAwayScore { get; set; }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            sb.Append(GameID);
            sb.Append('\t');
            sb.Append(HomeTeam);
            sb.Append('\t');
            sb.Append(AwayTeam);
            sb.Append('\t');
            sb.Append(Date);
            sb.Append('\t');
            sb.Append(HomeScore);
            sb.Append('\t');
            sb.Append(AwayScore);
            sb.Append('\t');
            sb.Append(PredictedHomeScore);
            sb.Append('\t');
            sb.Append(PredictedAwayScore);

            return sb.ToString();
        }

    }
}
