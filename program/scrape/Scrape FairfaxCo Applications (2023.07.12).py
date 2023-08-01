"""
This program uses selenium (http://www.seleniumhq.org/download/)
with a chromedriver (https://sites.google.com/chromium.org/driver/?pli=1)
to scrape rezoning application data.

See https://www.seleniumhq.org/docs/03_webdriver.jsp for details about Selenium.

Author: Colin Williams
Last updated: 12 July 2023
"""

from selenium import webdriver
from selenium.webdriver.chrome.options import Options

# Specify custom download directory
from selenium.webdriver.chrome.service import Service 

# Select drop-down menu
from selenium.webdriver.support.ui import Select

from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException, NoSuchElementException

import time
import random
import csv

import os

# Output filename
cwd = os.getcwd()

OUTPUT = cwd + "/data/FairfaxCo/Record Lists"

def init():
    agents = ['Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:96.0) Gecko/20100101 Firefox/96.0',               'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_16) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36 Edg/96.0.1054.29']

    chrome_options = Options()
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--ignore-certificate-errors')
    chrome_options.add_argument('--ignore-ssl-errors')
    chrome_options.add_argument("user-agent=" + agents[random.randint(0, len(agents) - 1)])
    
    # Specify custom download directory
    prefs = {'download.default_directory' : OUTPUT}
    chrome_options.add_experimental_option('prefs', prefs)

    newDriver = webdriver.Chrome(options=chrome_options)

    return newDriver

def scrape_fairfax(year = 2014):
    driver = init()
    driver.get("https://plus.fairfaxcounty.gov/CitizenAccess/Cap/CapHome.aspx?module=Zoning&TabName=Zoning&TabList=Home%7C0%7CBuilding%7C1%7CEnforcement%7C2%7CEnvHealth%7C3%7CFire%7C4%7CPlanning%7C5%7CSite%7C6%7CZoning%7C7%7CCurrentTabIndex%7C7")

    time.sleep(2)

    dropdown = Select(driver.find_element(By.NAME, "ctl00$PlaceHolderMain$generalSearchForm$ddlGSPermitType"))
    dropdown.select_by_visible_text("Rezoning")
    time.sleep(2)
               
    start_date = driver.find_element(By.NAME, "ctl00$PlaceHolderMain$generalSearchForm$txtGSStartDate")
    start_date.clear()
    start_date.click()
    start_date.send_keys("01/01/" + str(year))
    time.sleep(2)

    end_date = driver.find_element(By.NAME, "ctl00$PlaceHolderMain$generalSearchForm$txtGSEndDate")
    end_date.clear()
    end_date.click()
    end_date.send_keys("12/31/" + str(year))
    time.sleep(2)

    search_button = driver.find_element(By.ID, "ctl00_PlaceHolderMain_btnNewSearch")
    search_button.click()
    time.sleep(2)

    download_text = driver.find_element(By.ID, "ctl00_PlaceHolderMain_dgvPermitList_gdvPermitList_gdvPermitListtop4btnExport")
    download_text.click()
    time.sleep(2)

for year in range(2010, 2013):
    scrape_fairfax(year)
          
##############################################################################################################
if __name__ == "__main__":
    for year in range(2014, 2022):
        scrape_fairfax(year)

