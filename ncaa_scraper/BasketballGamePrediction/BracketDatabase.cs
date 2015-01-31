using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using MySql.Data.MySqlClient;

namespace BasketballGamePrediction
{
    class BracketDatabase
    {
        private static List<MySqlConnection> _mySqlConnections = new List<MySqlConnection>();
        private static MySqlConnectionStringBuilder _conStrBuilder;

        #region static MySqlConnection OpenDatabaseConnection()
        /// <summary>
        /// Opens and returns the MySqlConnection for the default database (hard-coded)
        /// </summary>
        /// <returns></returns>
        public static MySqlConnection GetDatabaseConnection()
        {
            
            if (_conStrBuilder == null)
            {
                _conStrBuilder = new MySqlConnectionStringBuilder();
                _conStrBuilder.UserID = "nodiffn1_mm2014";
                _conStrBuilder.Password = "mm2014vATL";
                _conStrBuilder.Server = "nodiff.net";
                _conStrBuilder.Database = "nodiffn1_mm2011";
                _conStrBuilder.Port = 3306;
                _conStrBuilder.DefaultCommandTimeout = 0;
            }
            foreach (MySqlConnection connection in _mySqlConnections)
            {
                if (connection.State == System.Data.ConnectionState.Closed)
                {
                    connection.Open();
                    return connection;
                }
            }
            MySqlConnection newConnection = new MySqlConnection(_conStrBuilder.ConnectionString);
            newConnection.Open();
            _mySqlConnections.Add(newConnection);

            return newConnection;
        }
        #endregion


    }
}
