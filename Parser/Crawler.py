from bs4 import BeautifulSoup
from urllib.request import *
import re
import os.path


# class Crawler:
def topAppsPackageName(redownload):
   # topAppsURL = ["https://play.google.com/store/apps/collection/topselling_free?hl=en",
   # "https://play.google.com/store/apps/collection/topselling_paid?hl=en",
   # "https://play.google.com/store/apps/category/GAME/collection/topselling_free?hl=en",
   # "https://play.google.com/store/apps/category/GAME/collection/topselling_paid?hl=en",
   # "https://play.google.com/store/apps/category/SOCIAL/collection/topselling_free?hl=en", #TOP APP IN SOCIAL (potentially the most vulnerable apps)
   # "https://play.google.com/store/apps/category/GAME_CASUAL/collection/topselling_free?hl=en",
   # "https://play.google.com/store/apps/category/GAME_CASUAL/collection/topselling_paid?hl=en",
   # "https://play.google.com/store/apps/category/GAME_STRATEGY/collection/topselling_paid",
   # "https://play.google.com/store/apps/category/GAME_STRATEGY/collection/topselling_free"
   # ]
   fname = "package_name.txt"

   packageNames = set()
   lines = [""]
   needDownload = redownload

   if(os.path.isfile(fname) and needDownload == False):
      with open(fname) as f:
         lines = f.readlines()

      for line in lines:
         newLine = line.rstrip("\n")
         packageNames.add(newLine)
   else:
      needDownload = True

   if(needDownload == True):
      maxChart = 500
      numAtATime = 120

      # maxChart = 10
      # numAtATime = 10

      topAppsURL = createUrls()

      for url in topAppsURL:
         print("new url is being processed: " + url)
         for start in range(1, maxChart, numAtATime):
            pageUrl = ""

            trial = 1

            while(trial < 3):
               try:
                  pageUrl = url + "&start=" + str(start) + "&num=" + str(numAtATime)
                  # print(pageUrl + "\n")

                  response = urlopen(pageUrl)

                  soup = BeautifulSoup(response.read())

                  # tag = soup.find_all("div", attrs={"data-docid":u
                  # re.compile("(([a-zA-Z]+){1}(\.[a-zA-Z]+)+)")})

                  # def containsPackageName(tag):
                  # return tag.has_attr('div')  #& (tag.get("data-docid") !=
                  # "none")

                  # tag = soup.find_all(containsPackageName)

                  tag = soup.find_all(
                      'span', attrs={'class': 'preview-overlay-container'})

                  for x in tag:
                     # print(x.encode('utf-8'))
                     # print(x.get("data-docid"))
                     packageNames.add(x.get("data-docid"))

                  trial = 3

               except urllib.error.HTTPError:
                  print("http error. Continue...")
                  trial = trial + 1

            # print(len(tag))

      text_file = open(fname, "w")
      for pkg in packageNames:
      	text_file.write(str(pkg) + "\n")

      text_file.close()

   print("Return " + str(len(packageNames)) + " app package names")

      # for n in packageName:
      # print(n)
      # https://play.google.com/store/apps/category/ARCADE/collection/topselling_paid?start=#{start}&num=24&hl=en

   return packageNames


def createUrls():
   prices = ["free", "paid"]
   categories = ["GAME", "SOCIAL", "GAME_CASUAL", "GAME_STRATEGY"]

   urls = []

   for price in prices:
      appsUrl = "https://play.google.com/store/apps/collection/topselling_" + \
          price + "?hl=en"
      urls.append(appsUrl)

      for category in categories:
         url = "https://play.google.com/store/apps/category/" + \
             category + "/collection/topselling_" + price + "?hl=en"
         urls.append(url)

   return urls
