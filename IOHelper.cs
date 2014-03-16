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
            // the connection object
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


            bool retreivedPage = false;
            string content = "";
            while (!retreivedPage)
            {
                try
                {
                    HttpWebRequest webRequest = (HttpWebRequest)HttpWebRequest.Create(URI);
                    // specifiy header values
                    webRequest.UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.146 Safari/537.36";
                    webRequest.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8";
                    webRequest.AutomaticDecompression = DecompressionMethods.GZip;
                    webRequest.CookieContainer = new CookieContainer(10);
                    //webRequest.Referer = "http://rivals.yahoo.com/ncaa/basketball";
                    // request a response
                    using (WebResponse response = webRequest.GetResponse())
                    {
                        using (Stream stream = response.GetResponseStream())
                        {
                            using (StreamReader reader = new StreamReader(stream))
                            {
                                content = reader.ReadToEnd();
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
                        File.AppendAllText(Program.logfileName, "sleeping for 61.46 minutes: " + e.Message + " at " + URI + "\n");
                        Thread.Sleep(TimeSpan.FromMinutes(61.46));
                    }
                    else if (e.Message.Contains("404"))
                    {
                        Console.WriteLine(e.Message + "; Skipping and going to the next team.");
                        File.AppendAllText(Program.logfileName, "Could not find the page; " + e.Message + " at " + URI + "\n");
                        content = null;
                        retreivedPage = true;
                    }
                    else
                    {
                        File.AppendAllText(Program.logfileName, "sleeping for 1.46 minutes: " + e.Message + " at " + URI + "\n");
                        Thread.Sleep(TimeSpan.FromMinutes(1.46));
                    }
                }
            }
            return content;
        }
        #endregion
    }
}
