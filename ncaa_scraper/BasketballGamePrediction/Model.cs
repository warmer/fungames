using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BasketballGamePrediction
{
    class Model
    {
        public string Name { get; set; }
        public int ID { get; set; }
        public int Version { get; set; }
        public string FeatureSelectQuery { get; set; }
        public string TeamSelectQuery { get; set; }
        public string PredictedFeature { get; set; }
        public string GroupbyQuery { get; set; }
        public DateTime EditDate { get; set; }

        public Feature[] Features { get; set; }
    }
}
