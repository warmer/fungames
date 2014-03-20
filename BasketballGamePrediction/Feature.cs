using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BasketballGamePrediction
{
    class Feature
    {
        public int ModelID { get; set; }
        public int Version { get; set; }
        public string FeatureName { get; set; }
        public float Weight { get; set; }
        public double Average { get; set; }
        public double Range { get; set; }
        public double Deviation { get; set; }
        public string Description { get; set; }
        public DateTime EditDate { get; set; }
    }
}
