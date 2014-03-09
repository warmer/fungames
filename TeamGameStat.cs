using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace YahooSportsStatsScraper
{
    class TeamGameStat
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

        public int TeamRebounds = -1;

        public void Copy(BasketballGamePlayer player)
        {
            this.Ast = player.Ast;
            this.Blk = player.Blk;
            this.FGA = player.FGA;
            this.FGM = player.FGM;
            this.FTA = player.FTA;
            this.FTM = player.FTM;
            this.Gid = player.Gid;
            this.Min = player.Min;
            this.Name = player.Name;
            this.Off = player.Off;
            this.PF = player.PF;
            this.Pts = player.Pts;
            this.Reb = player.Reb;
            this.Stl = player.Stl;
            this.TeamID = player.TeamID;
            this.TO = player.TO;
            this.TPA = player.TPA;
            this.TPM = player.TPM;
            this.YahooID = player.YahooID;
        }
        
        public static string getTotalInsertQuery()
        {
            return "INSERT IGNORE INTO tblteamgamestats (Name, yahooID, teamID, gameID, Min, FGM, FGA, TPM, TPA, FTM, FTA, Off, Reb, Ast, TRN, Stl, Blk, PF, Pts, TeamReb) VALUES ";
        }

        #region string ToQuery()
        public string ToQuery()
        {
            string query = String.Format("('{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}','{13}','{14}','{15}','{16}','{17}','{18}', '{19}')",
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
                    Pts,
                    TeamRebounds
                );

            return query;
        }
        #endregion
    }
}
