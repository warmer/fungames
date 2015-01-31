using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BasketballGamePrediction
{
    class TournamentGame
    {
        public string Region { get; set; }
        public int HighSeed { get; set; }
        public int Location { get; set; }
        public TournamentTeam HomeTeam { get; set; }
        public TournamentTeam AwayTeam { get; set; }
        public int Round { get; set; }
    }
}
