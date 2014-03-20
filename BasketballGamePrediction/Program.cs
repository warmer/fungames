using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using CommandLine;
using MySql.Data.MySqlClient;
using System.Reflection;
using System.IO;
using System.Diagnostics;
using System.Data;

namespace BasketballGamePrediction
{
    class Program
    {
        private const string OCTAVE_EXE = "C:\\Octave\\3.2.4_gcc-4.4.0\\bin\\octave-3.2.4.exe";
        private const string FIND_THETA_PROGRAM = "C:\\Users\\Kenneth\\Documents\\Projects\\Bracket\\ml\\train.txt";
        private const string PREDICT_PROGRAM = "C:\\Users\\Kenneth\\Documents\\Projects\\Bracket\\ml\\predict.txt";
        private const string FEATURE_FILE = "C:\\Users\\Kenneth\\Documents\\Projects\\Bracket\\ml\\newfeatures.tsv";
        private const string THETA_OUTPUT = "C:\\Users\\Kenneth\\Documents\\Projects\\Bracket\\ml\\theta";
        private const string SCORES_OUTPUT = "C:\\Users\\Kenneth\\Documents\\Projects\\Bracket\\ml\\scores";

        private const string NORMALIZE_FUNCTION = "({0}-{1})/{3}";

        private const string FEATURE_KEY = "%FEATURES%";
        private const string HOME_TEAM_KEY = "%HOMETEAM%";
        private const string AWAY_TEAM_KEY = "%AWAYTEAM%";
        private const string LOCATION_KEY = "%LOCATION%";
        private const string WITHHOLD_KEY = "%WITHHOLD%";
        private const string PREDICTED_FEATURE_KEY = "%PREDICTED_FEATURE%";
        private const string GROUPBY_KEY = "%GROUPBY%";
        private const string ATTENDANCE_KEY = "%ATTENDANCE%";

        private static Model getModel(string modelName)
        {
            modelName = modelName.Replace("'", "\'");

            if (String.IsNullOrWhiteSpace(modelName))
            {
                return null;
            }

            Model model = null;

            // look up the model in the database
            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                StringBuilder query = new StringBuilder("SELECT ");
                query.Append("Name");
                query.Append(", id");
                query.Append(", version");
                query.Append(", featureSelectQuery");
                query.Append(", teamSelectQuery");
                query.Append(", predictedFeature");
                query.Append(", groupbyQuery");
                query.Append(", editDate");
                query.Append(" FROM tblmodel WHERE Name='");
                query.Append(modelName);
                query.Append("';");

                MySqlCommand cmd = new MySqlCommand(query.ToString(), connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                if (dr.HasRows)
                {
                    model = new Model();
                    dr.Read();
                    model.Name = dr.GetString("Name");
                    model.ID = dr.GetInt32("id");
                    model.Version = dr.GetInt32("version");
                    model.FeatureSelectQuery = dr.GetString("featureSelectQuery");
                    model.TeamSelectQuery = dr.GetString("teamSelectQuery");
                    model.PredictedFeature = dr.GetString("predictedFeature");
                    model.GroupbyQuery = dr.GetString("groupbyQuery");
                    model.EditDate = dr.GetDateTime("editDate");
                }

            }

            return model;
        }

        private static string makeFeatureQuery(string featureSelectQuery, string[] features, int withhold, string groupbyString, string predictedFeature)
        {
            StringBuilder baseQuery = new StringBuilder(featureSelectQuery);

            baseQuery.Replace(WITHHOLD_KEY, withhold.ToString());
            // add the groupby part of the query if provided by the model
            if (String.IsNullOrEmpty(groupbyString))
            {
                groupbyString = "";
            }
            baseQuery.Replace(GROUPBY_KEY, groupbyString);
            // add the predicted feature if provided by the model
            if (String.IsNullOrEmpty(predictedFeature))
            {
                predictedFeature = "";
            }
            baseQuery.Replace(PREDICTED_FEATURE_KEY, predictedFeature);

            baseQuery.Replace(FEATURE_KEY, String.Join(", ", features));
            return baseQuery.ToString();
        }

        /// <summary>
        /// Retrieves the list of features from the argument passed in on the command line, with features separated by commas
        /// 
        /// Note: a feature can have commas in it; eg: max(1, 2) - and this will NOT treat those as separate features
        /// </summary>
        /// <param name="featureString"></param>
        /// <returns></returns>
        private static string[] getFeatureArray(string featureString)
        {
            int argCount = 0;
            List<string> features = new List<string>();
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < featureString.Length; i++)
            {
                if (featureString[i] == ',')
                {
                    // check if this separates features
                    if (argCount == 0)
                    {
                        features.Add(sb.ToString());
                        sb.Length = 0;
                        continue;
                    }
                }
                // going deeper into a nested method of a feature
                else if (featureString[i] == '(')
                {
                    argCount++;
                }
                // returning from a nested method of a feature
                else if (featureString[i] == ')')
                {
                    argCount--;
                }
                sb.Append(featureString[i]);
            }
            if (sb.Length > 0)
            {
                features.Add(sb.ToString());
            }
            return features.ToArray();
        }

        private static double[] getAdjustedFeatures(string adjustment, string[] features, Model model, int withhold)
        {
            string[] adjustedFeatureQueries = new string[features.Length];
            double[] adjustedFeatures = new double[features.Length];

            for (int i = 0; i < adjustedFeatureQueries.Length; i++)
            {
                adjustedFeatureQueries[i] = String.Format(adjustment, features[i]);
            }

            string featureQuery = makeFeatureQuery(model.FeatureSelectQuery, adjustedFeatureQueries, withhold, null, null);
            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                MySqlCommand cmd = new MySqlCommand(featureQuery, connection);
                MySqlDataReader dr = cmd.ExecuteReader();

                int rowCount = 0;
                while (dr.Read())
                {
                    if (dr.FieldCount != features.Length)
                    {
                        throw new Exception("The length of the columns returned in the feature adjustment query does not match the number of features!");
                    }
                    for (int i = 0; i < dr.FieldCount; i++)
                    {
                        double fieldValue = 0;
                        try
                        {
                            fieldValue = dr.GetDouble(i);
                        }
                        catch (Exception e)
                        {
                            Console.WriteLine("Error reading from MySqlDataReader: " + e.ToString());
                        }
                        adjustedFeatures[i] = fieldValue;
                    }
                    rowCount++;
                }
                if (rowCount != 1)
                {
                    throw new Exception("Wrong number of rows returned: " + rowCount);
                }
            }
            return adjustedFeatures;
        }

        /// <summary>
        /// Creates the training set specified by the model, then runs Octave to
        /// generate the Theta values, and adds those to the database
        /// </summary>
        /// <param name="options"></param>
        private static void updateModel(Options options)
        {
            int withhold = options.Withhold;
            Model model = getModel(options.ModelName);
            if(model == null)
            {
                return;
            }
            string[] featureArray = getFeatureArray(options.AddedFeatures);
            // calculate max/min/avg/stddev
            double[] averages = getAdjustedFeatures("AVG({0})", featureArray, model, withhold);
            double[] ranges = getAdjustedFeatures("MAX({0})-MIN({0})", featureArray, model, withhold);
            double[] deviations = getAdjustedFeatures("STDDEV({0})", featureArray, model, withhold);
            string[] normalizedFeatureArray = new string[featureArray.Length];

            // adjust the feature array query
            for (int i = 0; i < featureArray.Length; i++)
            {
                normalizedFeatureArray[i] = string.Format(NORMALIZE_FUNCTION, featureArray[i], averages[i], ranges[i], deviations[i]);
            }

            // look up the features in the database
            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                string featureQuery = makeFeatureQuery(model.FeatureSelectQuery, normalizedFeatureArray, withhold, model.GroupbyQuery, model.PredictedFeature);
                Console.WriteLine("FEATURE SELECT QUERY");
                Console.WriteLine("====================");
                Console.WriteLine(featureQuery);
                Console.WriteLine("====================");
                MySqlCommand cmd = new MySqlCommand(featureQuery, connection);
                MySqlDataReader dr = cmd.ExecuteReader();

                // write the feature file one line at a time
                using (TextWriter writer = File.CreateText(FEATURE_FILE))
                {
                    while (dr.Read())
                    {
                        for (int i = 0; i < dr.FieldCount; i++)
                        {
                            try
                            {
                                writer.Write(dr.GetString(i));
                            }
                            catch (Exception e)
                            {
                                Console.WriteLine("Error reading from MySqlDataReader: " + e.ToString());
                            }
                            if ((i + 1) < dr.FieldCount)
                            {
                                writer.Write('\t');
                            }
                        }
                        writer.WriteLine();
                    }
                }
            }

            ProcessStartInfo startInfo = new ProcessStartInfo(OCTAVE_EXE, "-q \"" + FIND_THETA_PROGRAM + "\"");
            startInfo.WindowStyle = ProcessWindowStyle.Hidden;
            Process octave = Process.Start(startInfo);
            octave.WaitForExit();

            string[] thetaFile = File.ReadAllLines(THETA_OUTPUT);
            Feature[] features = null;
            if (thetaFile.Length == featureArray.Length)
            {
                int version = getNextFeatureVersion(model);
                features = new Feature[thetaFile.Length];
                // look through every theta value
                for (int i = 0; i < thetaFile.Length; i++)
                {
                    Feature feature = new Feature();
                    float theta_i = float.Parse(thetaFile[i]);

                    feature.FeatureName = featureArray[i];
                    feature.Average = averages[i];
                    feature.Range = ranges[i];
                    feature.Deviation = deviations[i];
                    feature.Version = version;
                    feature.ModelID = model.ID;
                    feature.Weight = theta_i;

                    features[i] = feature;
                }

                addFeatures(features);
            }
            else
            {
                throw new Exception(String.Format("Problem with feature query - theta length {0} but feature length {1}", thetaFile.Length, featureArray.Length));
            }
        }

        public static void addFeatures(Feature[] features)
        {
            StringBuilder featureAddQuery = new StringBuilder();
            featureAddQuery.Append("INSERT INTO tblfeatures (modelID,version,featureName,weight,average,vrange,deviation) VALUES ");
            for (int i = 0; i < features.Length; i++)
            {
                featureAddQuery.Append('(');
                featureAddQuery.Append(features[i].ModelID);
                featureAddQuery.Append(',');
                featureAddQuery.Append(features[i].Version);
                featureAddQuery.Append(',');
                featureAddQuery.Append('"');
                featureAddQuery.Append(features[i].FeatureName);
                featureAddQuery.Append('"');
                featureAddQuery.Append(',');
                featureAddQuery.Append(features[i].Weight);
                featureAddQuery.Append(',');
                featureAddQuery.Append(features[i].Average);
                featureAddQuery.Append(',');
                featureAddQuery.Append(features[i].Range);
                featureAddQuery.Append(',');
                featureAddQuery.Append(features[i].Deviation);
                featureAddQuery.Append(')');
                featureAddQuery.Append(',');
            }
            // delete the trailing comma from the above loop
            featureAddQuery.Length = featureAddQuery.Length - 1;
            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                MySqlCommand cmd = new MySqlCommand(featureAddQuery.ToString(), connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                Console.WriteLine(dr.RecordsAffected + " rows affected.");
            }
        }

        private static int getNextFeatureVersion(Model model)
        {
            int version = 1;
            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                StringBuilder query = new StringBuilder("SELECT max(version) AS version FROM tblfeatures WHERE modelID=");
                query.Append(model.ID);
                query.Append(';');

                MySqlCommand cmd = new MySqlCommand(query.ToString(), connection);
                MySqlDataReader dr = cmd.ExecuteReader();

                if (dr.HasRows)
                {
                    dr.Read();
                    if (!dr.IsDBNull(dr.GetOrdinal("version")))
                    {
                        version = 1 + dr.GetInt32("version");
                    }
                }
            }
            return version;
        }

        private static void updateModelVersion(Model model)
        {
            throw new NotImplementedException();
        }

        private static Feature[] getFeatures(Model model)
        {
            List<Feature> features = new List<Feature>();
            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                StringBuilder query = new StringBuilder("SELECT ");
                query.Append("modelID");
                query.Append(", version");
                query.Append(", featureName");
                query.Append(", weight");
                query.Append(", description");
                query.Append(", average");
                query.Append(", vrange");
                query.Append(", deviation");
                query.Append(", editDate");
                query.Append(" FROM tblfeatures WHERE modelID=");
                query.Append(model.ID);
                query.Append(" AND version=");
                query.Append(model.Version);
                query.Append(';');

                MySqlCommand cmd = new MySqlCommand(query.ToString(), connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                if (dr.HasRows)
                {
                    while (dr.Read())
                    {
                        Feature feature = new Feature();

                        feature.ModelID = dr.GetInt32("modelID");
                        feature.Version = dr.GetInt32("version");
                        feature.FeatureName = dr.GetString("featureName");
                        feature.Weight = dr.GetFloat("weight");
                        feature.Average = dr.GetFloat("average");
                        feature.Range = dr.GetFloat("vrange");
                        feature.Deviation = dr.GetFloat("deviation");
                        if (!dr.IsDBNull(dr.GetOrdinal("description")))
                        {
                            feature.Description = dr.GetString("description");
                        }
                        feature.EditDate = dr.GetDateTime("editDate");
                        features.Add(feature);
                    }
                }
            }

            return features.ToArray();
        }

        private static void playTournament(Model model, TournamentTeam[] allTeams, int attendance, int round)
        {
            string gameSelectQuery = @"
                SELECT
                    region,
                    round,
                    highSeed,
                    locationID,
                    gameOrder
                FROM
                    tbltournamentgames
                WHERE round = " + round + @"
                ORDER BY region ASC, gameOrder ASC;";

            int teamIndex = 0;
            int gameIndex = 0;
            TournamentTeam[] survivingTeams = new TournamentTeam[(int)Math.Pow(2, 6 - round)];
            List<TournamentGame> roundGames = new List<TournamentGame>();

            if (allTeams.Length == 1 || round > 6)
            {
                return;
            }
            else if (allTeams.Length <= 4)
            {
                int location = 73;
                for (int i = 0; i < allTeams.Length / 2; i++)
                {
                    TournamentGame game = new TournamentGame()
                    {
                        AwayTeam = allTeams[teamIndex++],
                        HomeTeam = allTeams[teamIndex++],
                        HighSeed = 1,
                        Location = location,
                        Region = "FINFOUR"
                    };
                    roundGames.Add(game);
                }
            }

            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                MySqlCommand cmd = new MySqlCommand(gameSelectQuery, connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                if (dr.HasRows)
                {
                    while (dr.Read())
                    {
                        string region = dr.GetString("region");
                        int highSeed = dr.GetInt32("highSeed");
                        int location = dr.GetInt32("locationID");

                        TournamentGame game = new TournamentGame() {
                            AwayTeam = allTeams[teamIndex++], HomeTeam = allTeams[teamIndex++], HighSeed = highSeed, Location = location, Region = region
                        };

                        roundGames.Add(game);
                    }
                }
            }

            foreach (TournamentGame game in roundGames)
            {
                // predict
                Dictionary<string, float> predictions = predict(model, game.Location, game.HomeTeam.Team, attendance, game.AwayTeam.Team);
                float prediction = 0;
                if (predictions.Count == 1)
                {
                    prediction = predictions[predictions.Keys.First()];
                    Dictionary<string, float> predictions2 = predict(model, game.Location, game.AwayTeam.Team, attendance, game.HomeTeam.Team);
                    prediction = (prediction - predictions2[predictions2.Keys.First()]) / 2;
                }
                else if (predictions.Count == 2)
                {
                    prediction = predictions[game.HomeTeam.Team] - predictions[game.AwayTeam.Team];
                }
                //prediction += 13;
                TournamentTeam winner = prediction > 0 ? game.HomeTeam : game.AwayTeam;
                TournamentTeam loser = prediction <= 0 ? game.HomeTeam : game.AwayTeam;

                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < round; i++)
                {
                    sb.Append(' ');
                }
                sb.AppendFormat("[{5}-{6}] Predicted {0} ({1}) over {2} ({3}) by {4}", winner.Team, winner.Seed, loser.Team, loser.Seed, prediction, game.Region, round);
                survivingTeams[gameIndex++] = winner;
                if (winner.Seed > loser.Seed)
                {
                    sb.Append(" UPSET!");
                }
                Console.WriteLine(sb.ToString());

                // add the surviving team to the list
            }

            playTournament(model, survivingTeams, attendance, round + 1);
        }

        private static IEnumerable<int> getTeamsForRound(int round, int maxSeed)
        {
            int seedSum = (int)Math.Pow(2, 5 - round) + 1;

            if (round == 1)
            {
                return new int[] { maxSeed, seedSum - maxSeed }.AsEnumerable();
            }

            return getTeamsForRound(round - 1, maxSeed).Union(getTeamsForRound(round - 1, seedSum - maxSeed));
        }

        private static void predictTournament(Model model, int attendance, int round)
        {
            string firstRoundSelectQuery = @"SELECT
                    game.round,
                    game.region,
                    game.highSeed,
                    game.locationID
                FROM
                    tbltournamentgames AS game
                WHERE
                    game.round = " + round + @"
                ORDER BY
                    region ASC,
                    gameOrder ASC;";

            List<TournamentGame> firstRoundGames = new List<TournamentGame>();
            List<TournamentTeam> allTeams = new List<TournamentTeam>();

            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                MySqlCommand cmd = new MySqlCommand(firstRoundSelectQuery, connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                if (dr.HasRows)
                {
                    while (dr.Read())
                    {
                        string region = dr.GetString("region");
                        int highSeed = dr.GetInt32("highSeed");
                        int location = dr.GetInt32("locationID");

                        firstRoundGames.Add(new TournamentGame() { Region = region, HighSeed = highSeed, Location = location });
                    }
                }
            }

            foreach (TournamentGame game in firstRoundGames)
            {
                string possibleSeedString = String.Join(",", (from f in getTeamsForRound(round, game.HighSeed) select f.ToString()));
                string teamSelectQuery = String.Format(@"
                    SELECT seed, teamID FROM tbltournamentteam WHERE round={0} AND region='{1}' AND seed in({2});",
                    round,
                    game.Region,
                    possibleSeedString);
                using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
                {
                    MySqlCommand cmd = new MySqlCommand(teamSelectQuery, connection);
                    MySqlDataReader dr = cmd.ExecuteReader();
                    if (dr.HasRows)
                    {
                        while (dr.Read())
                        {
                            string teamID = dr.GetString("teamID");
                            int seed = dr.GetInt32("seed");
                            TournamentTeam team = new TournamentTeam() 
                            {
                                HighSeed = game.HighSeed,
                                Region = game.Region,
                                Seed = seed,
                                Team = teamID
                            };
                            allTeams.Add(team);
                        }
                    }
                }
            }

            playTournament(model, allTeams.ToArray(), attendance, round);
            Console.ReadKey();
        }

        private static Dictionary<string, float> predict(Model model, string hometeam, string awayteam)
        {
            return predict(model, 1, hometeam, 1, awayteam);
        }

        private static Dictionary<string, float> predict(Model model, int location, string hometeam, int attendance, string awayteam)
        {
            Dictionary<string, float> predictedValues = new Dictionary<string, float>();

            // find the features in the database
            if (model.Features == null)
            {
                model.Features = getFeatures(model);
            }

            // get the features for the teams involved
            Dictionary<string, float[]> teamFeatures = getTeamFeatures(
                hometeam,
                awayteam,
                location,
                attendance,
                model);

            if (teamFeatures.Keys.Count == 2)
            {
                foreach (String team in teamFeatures.Keys)
                {
                    float[] teamFeatureValues = teamFeatures[team];

                    float predictedValue = 0;
                    for (int i = 0; i < teamFeatureValues.Length; i++)
                    {
                        predictedValue += teamFeatureValues[i] * model.Features[i].Weight;
                    }
                    predictedValues.Add(team, predictedValue);
                }
            }
            else if (teamFeatures.Keys.Count == 1)
            {
                float[] teamFeatureValues = teamFeatures.Values.First();

                float predictedValue = 0;
                for (int i = 0; i < teamFeatureValues.Length; i++)
                {
                    predictedValue += teamFeatureValues[i] * model.Features[i].Weight;
                }
                predictedValues.Add(hometeam, predictedValue);
                //predictedValues.Add(awayteam, -predictedValue);
            }

            return predictedValues;
        }

        private static Dictionary<string, float[]> getTeamFeatures(string homeTeam, string awayTeam, int location, int attendance, Model model)
        {
            Dictionary<string, float[]> teamFeatures = new Dictionary<string, float[]>();

            StringBuilder query = new StringBuilder(model.TeamSelectQuery);
            query.Replace(FEATURE_KEY, String.Join(", ", (
                from f in model.Features
                select String.Format(NORMALIZE_FUNCTION, f.FeatureName, f.Average, f.Range, f.Deviation)).ToArray()));
            query.Replace(HOME_TEAM_KEY, String.Format("'{0}'", homeTeam));
            query.Replace(AWAY_TEAM_KEY, String.Format("'{0}'", awayTeam));
            query.Replace(AWAY_TEAM_KEY, String.Format("'{0}'", awayTeam));
            query.Replace(LOCATION_KEY, location.ToString());
            query.Replace(ATTENDANCE_KEY, attendance.ToString());

            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                MySqlCommand cmd = new MySqlCommand(query.ToString(), connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                if (dr.HasRows)
                {
                    if (dr.FieldCount == model.Features.Length)
                    {
                        int rowNumber = 0;
                        List<float[]> teamFeatureValues = new List<float[]>();
                        while (dr.Read())
                        {
                            if (rowNumber > 1)
                            {
                                Console.WriteLine("Too many feature rows were returned from the database. Aborting.");
                                while (dr.Read()) ;
                                dr.Close();
                                break;
                                //throw new Exception("Too many feature rows were returned from the database. Aborting.");
                            }
                            teamFeatureValues.Add(new float[dr.FieldCount]);
                            // populate the feature row
                            for (int i = 0; i < dr.FieldCount; i++)
                            {
                                teamFeatureValues[rowNumber][i] = dr.GetFloat(i);
                            }

                            rowNumber++;
                        }
                        if (teamFeatureValues.Count == 2)
                        {
                            teamFeatures.Add(homeTeam, teamFeatureValues[0]);
                            teamFeatures.Add(awayTeam, teamFeatureValues[1]);
                        }
                        else if (teamFeatureValues.Count == 1)
                        {
                            teamFeatures.Add(homeTeam, teamFeatureValues[0]);
                        }
                        else
                        {
                            throw new Exception("I don't know what to do with a feature list of length " + teamFeatureValues.Count);
                        }
                    }
                }
                else
                {
                    Console.WriteLine("No rows returned for matchup.");
                }
            }

            return teamFeatures;
        }

        private static void testModel(Model model)
        {
            string getGameQuery = @"
                SELECT
                    homeTeamYahooID AS homeTeam,
                    visitingTeamYahooID AS awayTeam,
                    CAST(homeScore - visitingScore AS signed) AS margin,
                    locationID,
                    attendance,
                    date
                FROM
                    tblgames
                WHERE
                    (ROUND(DEGREES(gameID)) % 100) >= 90
                    AND
                    visitingTeamYahooID != ''
                    AND
                    homeTeamYahooID != ''
                    AND locationID is not null
                    AND attendance >= 0
                ORDER BY
                    date DESC;
                ";

            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                MySqlCommand cmd = new MySqlCommand(getGameQuery, connection);
                MySqlDataReader dr = cmd.ExecuteReader();
                if (dr.HasRows)
                {
                    int correct = 0;
                    int total = 0;
                    while (dr.Read())
                    {
                        int location = dr.GetInt32("locationID");
                        string homeTeam = dr.GetString("homeTeam");
                        string awayTeam = dr.GetString("awayTeam");
                        int margin = dr.GetInt32("margin");
                        int attendance = dr.GetInt32("attendance");
                        DateTime date = dr.GetDateTime("date");

                        try
                        {
                            float prediction = 0;
                            Dictionary<string, float> predictions = predict(model, location, homeTeam, attendance, awayTeam);
                            if (predictions.Count == 1)
                            {
                                prediction = predictions[predictions.Keys.First()];
                            }
                            else if (predictions.Count == 2)
                            {
                                prediction = predictions[homeTeam] - predictions[awayTeam];
                            }
                            else
                            {
                                continue;
                            }

                            string winner = prediction > 0 ? homeTeam : awayTeam;
                            string loser = prediction <= 0 ? homeTeam : awayTeam;
                            total++;

                            if ((margin > 0 && prediction > 0) || (margin < 0 && prediction < 0))
                            {
                                correct++;
                                Console.WriteLine("++RIGHT\t{3}\tpredicted {0}\tactual {1}\tAvg: {2}", prediction, margin, (float)correct / (float)total, date.ToShortDateString());
                            }
                            else
                            {
                                Console.WriteLine("--WRONG\t{3}\tpredicted {0}\tactual {1}\tAvg: {2}", prediction, margin, (float)correct / (float)total, date.ToShortDateString());
                            }
                        }
                        catch (Exception e)
                        {
                            continue;
                        }
                    }
                    Console.WriteLine("{0} of {1} correct ({2})", correct, total, (float)correct / (float)total);
                }
            }
        }

        /// <summary>
        /// 
        /// </summary>
        private static void makePredictions(Options options)
        {
            string getGameQuery = "SELECT id, homeTeam, awayTeam, gameID FROM tblschedule WHERE gameID is null";

            MySqlCommand cmd;
            MySqlDataReader dr;
            List<Game> games = new List<Game>(300);
            using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
            {
                cmd = new MySqlCommand(getGameQuery.ToString(), connection);
                dr = cmd.ExecuteReader();

                while (dr.Read())
                {
                    Game game = new Game();

                    if (!dr.IsDBNull(dr.GetOrdinal("id")))
                    {
                        game.GameID = dr.GetInt32("id");
                    }
                    if (!dr.IsDBNull(dr.GetOrdinal("homeTeam")))
                    {
                        game.HomeTeam = dr.GetString("homeTeam");
                    }
                    if (!dr.IsDBNull(dr.GetOrdinal("awayTeam")))
                    {
                        game.AwayTeam = dr.GetString("awayTeam");
                    }

                    games.Add(game);
                }
                dr.Close();
            }

            Model model = getModel(options.ModelName);
            model.Version = options.Version;

            string predictionDate = DateTime.Now.ToString("yyyy-MM-dd");

            StringBuilder sb = new StringBuilder();
            foreach (Game game in games)
            {
                if (sb.Length == 0)
                {
                    sb.Append("INSERT INTO tblpredictions (predictionDate, scheduleId, modelID, version, homePrediction, awayPrediction) VALUES ");
                }
                Dictionary<string, float> predictions = predict(model, game.HomeTeam, game.AwayTeam);
                if (predictions == null || predictions.Keys.Count != 2)
                {
                    Console.WriteLine("Could not make a prediction for game ID: " + game.GameID);
                    continue;
                }
                game.PredictedAwayScore = predictions[game.AwayTeam];
                game.PredictedHomeScore = predictions[game.HomeTeam];
                Console.WriteLine(game);

                sb.Append('(');
                sb.Append('"' + predictionDate + '"');
                sb.Append(',');
                sb.Append(game.GameID);
                sb.Append(',');
                sb.Append(model.ID);
                sb.Append(',');
                sb.Append(model.Version);
                sb.Append(',');
                sb.Append(game.PredictedHomeScore);
                sb.Append(',');
                sb.Append(game.PredictedAwayScore);
                sb.Append(')');

                if (sb.Length > 2000)
                {
                    sb.Append(" ON DUPLICATE KEY UPDATE homePrediction=VALUES(homePrediction), awayPrediction=VALUES(awayPrediction)");
                    using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
                    {
                        cmd = new MySqlCommand(sb.ToString(), connection);
                        Console.WriteLine("Inserted {0} predictions.", cmd.ExecuteNonQuery());
                        sb.Clear();
                        sb.Length = 0;
                    }
                }
                else
                {
                    sb.Append(',');
                }
            }
            if (sb.Length > 0)
            {
                using (MySqlConnection connection = BracketDatabase.GetDatabaseConnection())
                {
                    cmd = new MySqlCommand(sb.ToString().Trim(','), connection);
                    Console.WriteLine("Inserted {0} predictions.", cmd.ExecuteNonQuery());
                }
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="args"></param>
        static void Main(string[] args)
        {
            var options = new Options();
            CommandLineParser parser = new CommandLineParser();
            parser.ParseArguments(args, options);

            if (options.Test)
            {
                //makePredictions(options);

                Model model = getModel(options.ModelName);
                model.Version = options.Version;
                testModel(model);
            }

            if (options.UpdateModel)
            {
                try
                {
                    updateModel(options);
                }
                catch (Exception e)
                {
                    Console.WriteLine(e.ToString());
                    Console.ReadKey();
                }
            }

            if (options.Tournament)
            {
                Model model = getModel(options.ModelName);
                model.Version = options.Version;
                predictTournament(model, options.Attendance, options.Round);
            }

            if (options.Predict)
            {
                Model model = getModel(options.ModelName);
                model.Version = options.Version;
                Dictionary<string, float> predictions = predict(model, options.HomeTeam, options.AwayTeam);
                foreach (string k in predictions.Keys)
                {
                    Console.WriteLine("Predicted value for {0} is {1}", k, predictions[k]);
                }
                Console.ReadKey();
            }
        }
    }
}
