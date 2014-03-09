using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace YahooSportsStatsScraper
{
    public abstract class Scraper
    {
        public int ScrapeDelay { get; set; }
        public string CacheDirectory { get; set; }
        public abstract string CacheSubDirectory { get; }

        public FileInfo[] getCachedFiles(string searchPattern)
        {
            string cacheDir = Path.Combine(CacheDirectory, CacheSubDirectory);
            IEnumerable<FileInfo> origCached = (new DirectoryInfo(cacheDir)).GetFiles(searchPattern).AsEnumerable();
            string backupPattern = searchPattern + IOHelper.BACKUP_EXT + "*";
            IEnumerable<FileInfo> allCached = origCached.Concat((new DirectoryInfo(cacheDir)).GetFiles(backupPattern).AsEnumerable());
            return allCached.ToArray();
        }

        public void cacheFile(string url, string cacheKey)
        {
            string page = IOHelper.GetWebPageAsString(url);
            string fullCacheDirectory = Path.Combine(CacheDirectory, CacheSubDirectory);
            IOHelper.saveFileWithBackup(fullCacheDirectory, cacheKey, page);
        }

        /// <summary>
        /// Start downloading files from the target location
        /// </summary>
        /// <returns>The number of files downloaded</returns>
        public abstract int scrape();

        /// <summary>
        /// Process the locally cached files
        /// </summary>
        /// <returns>The number of records processed</returns>
        public abstract int processLocalData();
    }
}
