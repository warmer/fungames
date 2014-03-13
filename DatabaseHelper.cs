using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using MySql.Data.MySqlClient;
using System.Text.RegularExpressions;
using System.Threading;

namespace YahooSportsStatsScraper
{
    class DatabaseHelper
    {
        public const int MAX_INSERT_LENGTH = 5000;

        private static MySqlConnection _connection;

        #region void LoadAllPlayerStats()
        public static List<TeamGameStat> LoadAllTeamGameStats()
        {
            List<TeamGameStat> teamGameStats = new List<TeamGameStat>();
            using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
            {
                string selectString =
                    String.Format("SELECT * FROM tblteamgamestats");
                MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder();
                MySqlCommand cmd = new MySqlCommand(selectString, Program.connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    TeamGameStat b = new TeamGameStat();
                    b.Gid = dr.GetString("gameID");
                    b.Name = dr.GetString("Name");
                    b.TeamID = dr.GetString("teamid");
                    b.YahooID = dr.GetString("yahooID");

                    b.Min = dr.GetInt32("Min");
                    b.Pts = dr.GetInt32("Pts");
                    b.FGM = dr.GetInt32("FGM");
                    b.FGA = dr.GetInt32("FGA");
                    b.TPM = dr.GetInt32("TPM");
                    b.TPA = dr.GetInt32("TPA");
                    b.FTM = dr.GetInt32("FTM");
                    b.FTA = dr.GetInt32("FTA");
                    b.Ast = dr.GetInt32("Ast");
                    b.Blk = dr.GetInt32("Blk");
                    b.Off = dr.GetInt32("Off");
                    b.Reb = dr.GetInt32("Reb");
                    b.PF = dr.GetInt32("PF");
                    b.Stl = dr.GetInt32("Stl");
                    b.TO = dr.GetInt32("TRN");
                    b.TeamRebounds = dr.GetInt32("TeamReb");
                    teamGameStats.Add(b);
                }
            }
            return teamGameStats;
        }
        #endregion

        #region void LoadAllPlayerStats()
        public static void LoadAllPlayerStats()
        {
            using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
            {
                string selectString =
                    String.Format("SELECT * FROM tblplayers, tblplayerteams WHERE tblplayerteams.playerid=tblplayers.yahooID");
                MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder();
                MySqlCommand cmd = new MySqlCommand(selectString, Program.connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    BasketballGamePlayer b = new BasketballGamePlayer();
                    b.Gid = dr.GetString("gameID");
                    b.Name = dr.GetString("Name");
                    b.TeamID = dr.GetString("teamid");
                    b.YahooID = dr.GetString("yahooID");

                    b.Min = dr.GetInt32("Min");
                    b.Pts = dr.GetInt32("Pts");
                    b.FGM = dr.GetInt32("FGM");
                    b.FGA = dr.GetInt32("FGA");
                    b.TPM = dr.GetInt32("TPM");
                    b.TPA = dr.GetInt32("TPA");
                    b.FTM = dr.GetInt32("FTM");
                    b.FTA = dr.GetInt32("FTA");
                    b.Ast = dr.GetInt32("Ast");
                    b.Blk = dr.GetInt32("Blk");
                    b.Off = dr.GetInt32("Off");
                    b.Reb = dr.GetInt32("Reb");
                    b.PF = dr.GetInt32("PF");
                    b.Stl = dr.GetInt32("Stl");
                    b.TO = dr.GetInt32("TRN");
                    Program.allPlayerStats.Add(b);
                }
            }
        }
        #endregion

        #region void LoadAllRawGames()
        /// <summary>
        /// Loads all the raw games from the database
        /// </summary>
        public static void LoadAllRawGames()
        {
            using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
            {
                try
                {
                    string selectString = String.Format("SELECT * FROM tblgames");
                    MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder();
                    MySqlCommand cmd = new MySqlCommand(selectString, Program.connection);
                    MySqlDataReader dr = cmd.ExecuteReader();
                    while (dr.Read())
                    {
                        RawGame rg = new RawGame(
                            dr.GetString("gameID"),
                            dr.GetString("yahooGameUrl"),
                            dr.GetString("homeTeamYahooID"),
                            dr.GetString("visitingTeamYahooID"),
                            dr.GetString("date"),
                            dr.GetInt32("homeScore"),
                            dr.GetInt32("visitingScore"));
                        Program.allRawGames.Add(rg);
                    }
                }
                catch (Exception e)
                {
                    Console.WriteLine(e.Message);
                }
            }
        }
        #endregion

        #region static MySqlConnection OpenDatabaseConnection()
        /// <summary>
        /// Opens and returns the MySqlConnection for the default database (hard-coded)
        /// </summary>
        /// <returns></returns>
        public static MySqlConnection OpenDatabaseConnection()
        {
            if (_connection == null || _connection.State != System.Data.ConnectionState.Open)
            {
                MySqlConnectionStringBuilder ConStrBuilder = new MySqlConnectionStringBuilder();
                ConStrBuilder.UserID = "nodiffn1_mm2014";
                ConStrBuilder.Password = "mm2014vATL";
                ConStrBuilder.Server = "nodiff.net";
                ConStrBuilder.Database = "nodiffn1_mm2011";
                ConStrBuilder.AllowUserVariables = true;
                ConStrBuilder.Port = 3306;

                _connection = new MySqlConnection(ConStrBuilder.ConnectionString);
                bool success = false;
                int retries = 0;
                double sleepTime = 0;
                while (!success && retries < 10)
                {
                    try
                    {
                        _connection.Open();
                        success = true;
                    }
                    catch (Exception e)
                    {
                        retries++;
                        sleepTime = Math.Pow(retries, 2);
                        Console.WriteLine("Problem opening connection; retrying for {0} seconds. Error: {1}", sleepTime, e.Message);
                        Thread.Sleep(TimeSpan.FromSeconds(sleepTime));
                    }
                }
            }
            return _connection;
        }
        #endregion

        #region static MySqlConnection OpenDatabaseConnection(MySqlConnectionStringBuilder ConStrBuilder)
        /// <summary>
        /// Opens a connection to a database given the connection string via the
        /// MySqlConnectionStringBuilder object
        /// </summary>
        /// <param name="ConStrBuilder"></param>
        /// <returns></returns>
        public static MySqlConnection OpenDatabaseConnection(MySqlConnectionStringBuilder ConStrBuilder)
        {
            MySqlConnection aConnection = new MySqlConnection(ConStrBuilder.ConnectionString);
            aConnection.Open();
            return aConnection;
        }
        #endregion

        #region static List<string> GetTeamsFromDatabase()
        /// <summary>
        /// Uses the default database connection and a Dictionary of team names and team codes
        /// to populate the "teams" table
        /// </summary>
        /// <param name="startTeam">start team hint</param>
        /// <returns>the number of teams that were inserted</returns>
        public static List<string> GetTeamsFromDatabase(string startTeam)
        {
            if (String.IsNullOrEmpty(startTeam))
            {
                startTeam = "";
            }
            else
            {
                Match teamMatch = Regex.Match(startTeam, "[a-z]*");
                if (teamMatch == null)
                {
                    startTeam = "";
                }
                else if (teamMatch.Captures.Count < 1)
                {
                    startTeam = "";
                }
                else if (teamMatch.Captures[0].Value != startTeam)
                {
                    startTeam = "";
                }
            }

            List<string> teamIDs = new List<string>();
            using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
            {
                string selectString = String.Format("SELECT yahooID FROM tblteams WHERE yahooID > '{0}'", startTeam);
                MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder();
                MySqlCommand cmd = new MySqlCommand(selectString, Program.connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    teamIDs.Add(dr.GetString(0));
                }
            }
            return teamIDs;
        }
        #endregion

        public static string getTeamId(string teamName)
        {
            string teamId = "";
            Program.connection = DatabaseHelper.OpenDatabaseConnection();
            string query = String.Format("select yahooID from tblteams where team=\"{0}\";", teamName);
            MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder();
            using (MySqlCommand cmd = new MySqlCommand(query, Program.connection))
            {
                using (MySqlDataReader dr = cmd.ExecuteReader())
                {
                    while (dr.Read())
                    {
                        teamId = dr.GetString(0);
                    }
                }
            }
            return teamId;
        }

        public static Dictionary<string, string> getGamesWithoutStats()
        {
            Dictionary<string, string> gameUrlDict = new Dictionary<string, string>();

            string query = "SELECT tblgames.yahooGameUrl, tblgames.gameID FROM tblgames LEFT JOIN tblteamgamestats ON tblgames.gameID=tblteamgamestats.gameID WHERE tblteamgamestats.Name is null;";

            using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
            {
                using (MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder())
                {
                    using (MySqlCommand cmd = new MySqlCommand(query, Program.connection))
                    {
                        using (MySqlDataReader dr = cmd.ExecuteReader())
                        {
                            while (dr.Read())
                            {
                                gameUrlDict[dr.GetString(1)] = dr.GetString(0);
                            }
                        }
                    }
                }
            }
            return gameUrlDict;
        }

        #region static List<string> GetGamesFromDatabase()
        /// <summary>
        /// Uses the default database connection and a Dictionary of team names and team codes
        /// to populate the "teams" table
        /// </summary>
        /// <param name="TeamsList">key: team_name, value: yahooID</param>
        /// <returns>the number of teams that were inserted</returns>
        public static List<string> GetGamesFromDatabase(long startingGameNumber, long endingGameNumber)
        {
            List<string> gameIDs = new List<string>();
            using (Program.connection = DatabaseHelper.OpenDatabaseConnection())
            {
                string selectString = String.Format("SELECT gameID FROM tblgames WHERE gameID > {0} AND gameID <= {1}", startingGameNumber, endingGameNumber);
                MySqlCommandBuilder cmdBuilder = new MySqlCommandBuilder();
                MySqlCommand cmd = new MySqlCommand(selectString, Program.connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                while (dr.Read())
                {
                    gameIDs.Add(dr.GetString(0));
                }
            }
            return gameIDs;
        }
        #endregion
    }
}
