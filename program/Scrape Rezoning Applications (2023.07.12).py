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
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException, NoSuchElementException

import time
import random
import csv

import os

# Output filename
cwd = os.getcwd()

OUTPUT = cwd + "\\data\\FairfaxCo\\RezoningApplications.csv"
DRIVER = cwd + "\\chromedriver\\chromedriver.exe"

# Note working yet
# See https://sites.google.com/chromium.org/driver/getting-started?authuser=0
driver = webdriver.Chrome(DRIVER)
driver.get("http://www.google.com/")
time.sleep(5)
search_box = driver.find_element_by_name("q")
search_box.send_keys("ChromeDriver")
search_box.submit()
time.sleep(5)
driver.quit()

def selenium_scrape():
    driver = init()
    driver.get("https://www.taxpayerservicecenter.com/RP_Search.jsp?search_type=Assessment")
    write_header() # replaces output file!

    select = driver.find_element_by_name("selectNbhdCode")
    # neighborhoods = select.find_elements_by_tag_name("option")
    # neighborhoods = ["Georgetown"] # and change to neighborhood.text below
    #for neighborhood in neighborhoods:
    scrape_neighborhood(driver, neighborhood = "", dateStart = "12/5/2018", dateEnd="4/24/2019")
    
def write_header():
    variables = ['Lot', 'Address', 'Owner', 'Neighborhood', 'Sub-Neighborhood', 'UseCode', 'SalePrice', 'RecordationDate', '2018TotalAssessment']
    with open(OUTPUT, "w+", newline='') as f:
        writer = csv.writer(f)
        writer.writerow(variables)
    f.close()

def scrape_neighborhood(driver, neighborhood, dateStart, dateEnd):
    # driver.find_element_by_name("selectNbhdCode").send_keys(neighborhood)
    driver.find_element_by_name("dtFrom").send_keys(dateStart)
    driver.find_element_by_name("dtTo").send_keys(dateEnd)
    driver.find_element_by_id("imgSearch").click()

    with open(OUTPUT, "a+", newline='') as f:
        writer = csv.writer(f)
        
        next = None
        while not next:
      
            data = driver.find_elements_by_class_name('Std')
            to_csv(data, writer)

            data = driver.find_elements_by_class_name('WhiteRow')
            to_csv(data, writer)

            try:
                next = driver.find_element_by_xpath("//*[contains(text(), 'next')]").click()
            except NoSuchElementException:
                break  

def to_csv(data, writer):
    i = 1
    obs = []
    for item in data:
        if i < 9:
            obs.append(item.text)
            i += 1
        else:
            obs.append(item.text)
            writer.writerow(obs)

            obs = []
            i = 1

def init(browser = "Chrome"):
    agents = ['Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A',
              'Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16']

    chrome_options = Options()
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--ignore-certificate-errors')
    chrome_options.add_argument('--ignore-ssl-errors')
    chrome_options.add_argument("user-agent=" + agents[random.randint(0, 2)])
    newDriver = webdriver.Chrome(executable_path="C:\\Users\\colin.williams\\Documents\\Python\\Scraping\\chromedriver_win32\\chromedriver.exe", options=chrome_options)

    return newDriver
          
##############################################################################################################
if __name__ == "__main__":
    selenium_scrape()