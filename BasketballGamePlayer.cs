using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace YahooSportsStatsScraper
{
    class BasketballGamePlayer
    {
        #region members
        public string TeamID;

        public string Name;
        public string YahooID;
        public string Gid;
        public int Min = -1;
        public int FGM = -1;
        public int FGA = -1;
        public int TPM = -1;
        public int TPA = -1;
        public int FTM = -1;
        public int FTA = -1;
        public int Off = -1;
        public int Reb = -1;
        public int Ast = -1;
        public int TO = -1;
        public int Stl = -1;
        public int Blk = -1;
        public int PF = -1;
        public int Pts = -1;
        #endregion

        public static string getInsertQuery()
        {
            return "INSERT IGNORE INTO tblplayerscorrected (Name, yahooID, teamID, gameID, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, Pts) VALUES ";
        }

        #region string ToQuery()
        public string ToQuery()
        {
            string query = String.Format("('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}','{16}','{17}','{18}')",
                    Name.Replace("\'", "\\\'"),
                    YahooID,
                    TeamID,
                    Gid,
                    Min,
                    FGM,
                    FGA,
                    TPM,
                    TPA,
                    FTM,
                    FTA,
                    Off,
                    Reb,
                    Ast,
                    TO,
                    Stl,
                    Blk,
                    PF,
                    Pts
                );

            return query;
        }
        #endregion
    }

}
