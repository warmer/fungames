using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using CommandLine;

namespace BasketballGamePrediction
{
    class Options
    {
        [Option(null, "updateModel", DefaultValue = false, HelpText =
            "Using an existing model, find the latest version " +
            "of the features and re-run linear regression algorthm " +
            "to define new theta values")]
        public bool UpdateModel { get; set; }

        [Option(null, "attendance", DefaultValue = 2000, HelpText =
            "Anticipated attendance")]
        public int Attendance { get; set; }

        [Option(null, "withhold", DefaultValue = 0, HelpText =
            "Percent of data to withhold")]
        public int Withhold { get; set; }

        [Option(null, "tournament", DefaultValue = false, HelpText =
            "Predict tournament results")]
        public bool Tournament { get; set; }

        [Option(null, "round", DefaultValue = 3, HelpText =
            "Starting round for the tournament predictions")]
        public int Round { get; set; }

        [Option(null, "predict", DefaultValue = false, HelpText =
            "Uses stored theta values to predict results")]
        public bool Predict { get; set; }

        [Option(null, "test", DefaultValue = false, HelpText =
            "Test the specified model against played games")]
        public bool Test { get; set; }

        [Option("o", "outputFile", Required = false, HelpText = "File where the features should be saved for testing the model")]
        public string OutputFile { get; set; }

        [Option(null, "useLatest", DefaultValue = false, HelpText =
            "Use the features from the latest version of the model as " +
            "a basis for updating the given model.")]
        public bool UseLatestModel { get; set; }

        [Option("f", "features", HelpText =
            "Specify features to include in the model, separated by commas")]
        public string AddedFeatures { get; set; }

        [OptionList(null, "omit", Separator = ',', HelpText =
            "Specify features to omit from the model, separated by commas")]
        public IList<string> OmittedFeatures { get; set; }

        //[Option(null, "featureFile", HelpText =
        //    "Where to write the feature file")]
        //public string FeatureFile { get; set; }

        [Option("H", "homeTeam", Required = false, HelpText = "Home team yahoo code")]
        public string HomeTeam { get; set; }

        [Option("a", "awayTeam", Required = false, HelpText = "Away team yahoo code")]
        public string AwayTeam { get; set; }

        [Option(null, "modelName", Required = true, HelpText = "The name of the model to use")]
        public string ModelName { get; set; }

        [Option(null, "version", HelpText = "The model version to use")]
        public int Version { get; set; }
    }

}
