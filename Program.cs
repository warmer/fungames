using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

using MySql.Data.MySqlClient;

using CommandLine;
using CommandLine.Text;

namespace YahooSportsStatsScraper
{
    class Options
    {
        [Option(null, "getTeams", HelpText = 
            "Gets the list of teams from" +
            " the default Yahoo! Sports teams URL" +
		    "and loads them into the default hard-coded database")]
        public bool GetTeams { get; set; }

        [Option(null, "getGames", HelpText =
            "Uses the team codes that are retrieved with the get_teams option\n" +
            "\t\tto poll each team page from Yahoo! Sports using the default\n" +
            "\t\thard-coded URL\n" +
            "\t\t(http://rivals.yahoo.com/ncaa/basketball/teams/[TEAMCODE])\n" +
            "\t\tNote that this doesn't actually get scores; it simply populates\n" +
            "\t\tthe 'tblgames' database table with the following information:\n" +
            "\t\t\t* Yahoo! Sports gid (bigint(20))\n" +
            "\t\t\t* Yahoo! Sports team ID for the home team (varchar(3))\n" +
            "\t\t\t* Yahoo! Sports team ID for the visiting team (varchar(3))\n" +
            "\t\t\t* home score (int(10))\n" +
            "\t\t\t* visiting score (int(10))\n" +
            "\t\t\t* date the game was played (date)\n" +
            "\t\tpoll_period is the number of seconds between eatch page fetch\n" +
            "\t\tstart_team is the three-digit string corresponding to\n" +
            "\t\t\tthe _last_ team that was scraped (it is non-inclusive)\n")]
        public bool GetGames { get; set; }

        [Option(null, "getRoster", HelpText = 
            "Unimplemented")]
        public bool GetRoster { get; set; }

        [Option(null, "getTeamStats", HelpText =
            "Unimplemented")]
        public bool GetTeamStats { get; set; }

        [Option(null, "getBoxscores", HelpText =
            "Uses the Yahoo! Sports gid table to download each game's boxscore")]
        public bool GetBoxscores { get; set; }

        [Option(null, "checkGames", HelpText =
            "Reads player and game stats, then determines if the stats match" +
		    "(eg: sum of points in a game equals sum of player stats for points)")]
        public bool CheckGames { get; set; }

        [Option("d", "delay", DefaultValue = 10, HelpText = 
            "The delay between scraping individual pages from the source")]
        public int ScrapeDelay { get; set; }

        [Option(null, "startTeam", DefaultValue = "aaa", HelpText =
            "When discovering games or scraping rosters, start with this team")]
        public string StartTeam { get; set; }

        [Option(null, "startGame", DefaultValue = 201211010000L, HelpText =
            "When downloading boxscores, start with the given game ID")]
        public long StartGame { get; set; }

        [Option(null, "endGame", DefaultValue = 209912319999L, HelpText =
            "When downloading boxscores, end with the given game ID")]
        public long EndGame { get; set; }

        [Option("l", "localOnly", HelpText = "Use only locally-cached files for processing")]
        public bool LocalOnly { get; set; }

        [Option("c", "cacheDir", Required = true, HelpText = "Location of local cache")]
        public string CacheDirectory {get;set;}

        [HelpOption]
        public string GetUsage()
        {
            var usage = new StringBuilder();
            usage.AppendLine("Yahoo! Boxscore scraper; written by Kenneth Kinion");
            usage.AppendLine("First version: March Madness 2009");
            return usage.ToString();
        }
    }

    class Program
    {
        #region static members
        public static MySqlConnection connection;
        public static string logfileName = "C:\\Users\\Kenneth\\Documents\\Projects\\Bracket\\newlogfile.txt";
        //MySqlConnectionStringBuilder ConStrBuilder;
        //public static bool connectionStringBuilt;
        public static List<BasketballGamePlayer> allPlayerStats = new List<BasketballGamePlayer>();
        public static List<RawGame> allRawGames = new List<RawGame>();
        #endregion

        private static void test()
        {
            Dictionary<string, TeamStats> teamStats = new Dictionary<string, TeamStats>();
            List<TeamGameStat> teamGameStats = DatabaseHelper.LoadAllTeamGameStats();

            foreach (TeamGameStat stat in teamGameStats)
            {
                string name = stat.TeamID;
            }
        }

        #region PrintHelp()
        /// <summary>
        /// Prints a help message to the console
        /// </summary>
        public static void PrintHelp()
        {
            FileInfo helpFile = new FileInfo("Help.txt");
            if (!helpFile.Exists)
            {
                Console.WriteLine("You did something wrong, but the help file is missing.");
            }
            else
            {
                StreamReader sr = File.OpenText(helpFile.FullName);
                string line;
                while ((line = sr.ReadLine()) != null)
                {
                    Console.WriteLine(line);
                }
            }
        }
        #endregion

        /// <summary>
        /// The main entry point for the program
        /// </summary>
        /// <param name="args"></param>
        static void Main(string[] args)
        {
            var options = new Options();
            CommandLineParser parser = new CommandLineParser();
            parser.ParseArguments(args, options);

            int pollPeriod = options.ScrapeDelay;
            if (options.GetTeams)
            {
                TeamListScraper teamListScraper = new TeamListScraper();
                teamListScraper.CacheDirectory = options.CacheDirectory;
                teamListScraper.ScrapeDelay = options.ScrapeDelay;
                if (!options.LocalOnly)
                {
                    teamListScraper.scrape();
                }
                teamListScraper.processLocalData();
            }
            if (options.GetGames)
            {
                GameScraper gameScraper = new GameScraper();
                gameScraper.ScrapeDelay = options.ScrapeDelay;
                gameScraper.CacheDirectory = options.CacheDirectory;
                gameScraper.StartTeam = options.StartTeam;
                if (!options.LocalOnly)
                {
                    gameScraper.scrape();
                }
                gameScraper.processLocalData();
            }
            if(options.GetBoxscores)
            {
                BoxscoreScraper scraper = new BoxscoreScraper();
                scraper.CacheDirectory = options.CacheDirectory;
                scraper.StartGame = options.StartGame;
                scraper.ScrapeDelay = options.ScrapeDelay;
                scraper.EndGame = options.EndGame;
                if (!options.LocalOnly)
                {
                    scraper.scrape();
                }
                scraper.processLocalData();
            }
            if(options.CheckGames)
            {
                BoxscoreScraper scraper = new BoxscoreScraper();
                scraper.CacheDirectory = options.CacheDirectory;
                scraper.CheckGames();
            }
        } // END main()
    }
}
