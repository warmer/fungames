using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.IO;
using System.Threading;

namespace YahooSportsStatsScraper
{
    class IOHelper
    {
        private const int MAX_CACHE_VERSION = 2;
        public const string BACKUP_EXT = ".v";

        /// <summary>
        /// Saves the given content to a file
        /// </summary>
        /// <param name="storageDir"></param>
        /// <param name="fileName"></param>
        /// <param name="content"></param>
        public static void saveFileWithBackup(string storageDir, string fileName, String content)
        {
            if (!Directory.Exists(storageDir))
            {
                Directory.CreateDirectory(storageDir);
            }
            string filePath = Path.Combine(storageDir, fileName);

            if (File.Exists(filePath))
            {
                int version = 0;
                string backupFile = filePath + BACKUP_EXT + version;
                while (File.Exists(backupFile))
                {
                    if (version == MAX_CACHE_VERSION)
                    {
                        File.Delete(backupFile);
                        break;
                    }

                    version++;
                    backupFile = filePath + BACKUP_EXT + version;
                }
                File.Move(filePath, backupFile);
            }
            File.AppendAllText(filePath, content);
        }

        #region static string GetWebPageAsString(string URI)
        /// <summary>
        /// Returns a webpage with the specified URI as a string
        /// </summary>
        /// <param name="URI"></param>
        /// <returns></returns>
        public static string GetWebPageAsString(string URI)
        {
            string PageContent = "";
            // the connection object
            HttpWebRequest MyWebRequest = (HttpWebRequest)HttpWebRequest.Create(URI);
            //if (!String.IsNullOrEmpty(proxy))
            //{
            //    WebProxy myProxy = new WebProxy();
            //    myProxy.Address = new Uri(proxy);
            //    myProxy.Credentials = new NetworkCredential("", "", "");
            //    MyWebRequest.Proxy = myProxy;

            //    //string UrlToEncode = URI.Substring(4);
            //    //byte[] encDataByte = System.Text.Encoding.UTF8.GetBytes(UrlToEncode);
            //    //string encodedData = Convert.ToBase64String(encDataByte);

            //    //MyWebRequest = (HttpWebRequest)HttpWebRequest.Create(proxy + encodedData);
            //    //MyWebRequest.Referer = proxy;

            //    ////217.69.239.69:8080

            //}

            // specifiy header values
            MyWebRequest.UserAgent = ".NET Framework/2.0 Yahoo! Sports Statistics Addict";
            MyWebRequest.Referer = "http://rivals.yahoo.com/ncaa/basketball";

            bool retreivedPage = false;
            while (!retreivedPage)
            {
                try
                {
                    // request a response
                    using (WebResponse MyResponse = MyWebRequest.GetResponse())
                    {
                        using (Stream MyWebStream = MyResponse.GetResponseStream())
                        {
                            using (StreamReader MyReader = new StreamReader(MyWebStream))
                            {
                                PageContent = MyReader.ReadToEnd();
                                retreivedPage = true;
                            }
                        }
                    }
                }
                catch (Exception e)
                {
                    Console.WriteLine(e.Message);
                    if (e.Message.Contains("999"))
                    {
                        File.AppendAllText(Program.logfileName, "sleeping for 61.46 minutes: " + e.Message + " at " + URI);
                        Thread.Sleep(TimeSpan.FromMinutes(61.46));
                    }
                    else
                    {
                        File.AppendAllText(Program.logfileName, "sleeping for 1.46 minutes: " + e.Message + " at " + URI);
                        Thread.Sleep(TimeSpan.FromMinutes(1.46));
                    }
                }
            }
            return PageContent;
        }
        #endregion
    }
}
