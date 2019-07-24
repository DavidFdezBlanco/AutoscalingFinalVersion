using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using System.Timers;
using Microsoft.Azure.Management.Automation;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

namespace AutoscalingFinalVersion
{
    public partial class Service1 : ServiceBase
    {
        Timer timer = new Timer(); // name space(using System.Timers;)
        Timer timerEval = new Timer();

        //Http service declaration
        private HttpServer httpServer = null;
        private System.Threading.Thread threadHttp;
        
        //Time before evaluating requests
        private int updateTimeEvaluation = 15000;

        //Cooldown variables
        private bool cooldownAS = false;
        private bool cooldownES = false;

        //ES index
        private string indexESDATA = "000015";
        
        //AS Status array
        private string[,] ASMachinesStatus = new string[5,3]; //index,Name,ip,status(up/down)

        //Time stamp last creation or deletion
        private long timeMillisecond = 0;

        public Service1()
        {
            InitializeComponent();
        }
        protected override void OnStart(string[] args)
        {
            //Service status log report
            WriteToLogFile("Service is started at " + DateTime.Now);
            timer.Elapsed += new ElapsedEventHandler(OnElapsedTime);
            timer.Interval = 50000; //number in milisecinds every 50s
            timer.Enabled = true;

            //Performance Evaluation
            timerEval.Elapsed += new ElapsedEventHandler(EvaluatePerformance); //Event to be coded
            timerEval.Interval = updateTimeEvaluation; //number in milisecinds  
            timerEval.Enabled = true;

            //Http Server instanciation
            httpServer = new MyHttpServer(8080);
            threadHttp = new System.Threading.Thread(new System.Threading.ThreadStart(httpServer.listen));
            threadHttp.Start();
                     

            //Retrieve the last index given to all kinds of machines
            string pathIndexes = AppDomain.CurrentDomain.BaseDirectory + "\\Logs\\Indexes\\IndexData.txt";
            StreamReader srIndexes = new StreamReader(pathIndexes);
            string indexValue;
            List<string> indexesValues = new List<string>();
            while ((indexValue = srIndexes.ReadLine()) != null)
            {
                indexesValues.Add(indexValue);
            }
            srIndexes.Close();
     
            indexESDATA = GetLastInstanceOf(indexesValues, "indexESDATA");
            fullfillTableAS();
        }

        private void fullfillTimeLastCreation()
        {
            string pathFile = AppDomain.CurrentDomain.BaseDirectory + "Logs\\Cooldowns\\LastCreationAS.txt";
            StreamReader sr = new StreamReader(pathFile);
            string asInformation = sr.ReadLine();
            string[]asInformationSplitted = asInformation.Split(':');
            timeMillisecond = Convert.ToInt64(asInformationSplitted[1]);
            sr.Close();
        }

        private void writeToCooldownFile()
        {
            string pathFile = AppDomain.CurrentDomain.BaseDirectory + "Logs\\Cooldowns\\LastCreationAS.txt";
            if (!File.Exists(pathFile))
            {
                // Create a file to write to.   
                using (StreamWriter sw = File.CreateText(pathFile))
                {
                    sw.WriteLine("TimeStamp:" + timeMillisecond); //make the same for the other kinds
                }
            }
            else
            {
                File.Delete(pathFile);
                File.Delete(pathFile);
                using (StreamWriter sw = File.CreateText(pathFile))
                {
                    sw.WriteLine("TimeStamp:" + timeMillisecond); //make the same for the other kinds
                }
            }
        }

        private void fullfillTableAS()
        {
            string pathIndexesFile = AppDomain.CurrentDomain.BaseDirectory + "\\Resources\\CREATE_VM_FROM_IMAGE\\IPConfigs\\ipFix.txt";
            StreamReader sr = new StreamReader(pathIndexesFile);
            
            int i = 0;
            string asInformation;
            while ((asInformation = sr.ReadLine()) != null)
            {
                string[] splittedInfomrations = asInformation.Split(',');
                ASMachinesStatus[i, 0] = splittedInfomrations[0];
                ASMachinesStatus[i, 1] = splittedInfomrations[1];
                ASMachinesStatus[i, 2] = splittedInfomrations[2];
                i = i + 1;
            }
            sr.Close();

            WriteToLogFile("Fullfilling table with the current AS status");
            i = 0;
            for (i = 0; i < 5; i++)
            {
                if(ASMachinesStatus[i, 0] != null)
                {
                    WriteToLogFile("Name : " + ASMachinesStatus[i, 0] + " IP : " + ASMachinesStatus[i, 1] + " Status : " + ASMachinesStatus[i, 2]);
                }
            }
                
        }

        private string GetLastInstanceOf(List<string> Indexes, string Index)
        {
            foreach (string a in Indexes)
            {
                string[] toCompare = a.Split(':');
                if (toCompare[0] == Index)
                {
                    return toCompare[1];
                }
            }
            return "000000";
        }
        private string GetNextESData()
        {
            int indexESDataInt = Int32.Parse(indexESDATA);
            indexESDataInt++;
            if (indexESDataInt < 10)
            {
                string toOutput = "00000" + indexESDataInt;
                indexESDATA = toOutput;
            }
            else if (indexESDataInt >= 10 && indexESDataInt < 100)
            {
                string toOutput = "0000" + indexESDataInt;
                indexESDATA = toOutput;
            }
            else if (indexESDataInt >= 100 && indexESDataInt < 1000)
            {
                string toOutput = "000" + indexESDataInt;
                indexESDATA = toOutput;
            }
            else if (indexESDataInt >= 1000 && indexESDataInt < 10000)
            {
                string toOutput = "00" + indexESDataInt;
                indexESDATA = toOutput;
            }
            else if (indexESDataInt >= 10000 && indexESDataInt < 100000)
            {
                string toOutput = "0" + indexESDataInt;
                indexESDATA = toOutput;
            }
            else if (indexESDataInt >= 100000)
            {
                string toOutput = "" + indexESDataInt;
                indexESDATA = toOutput;
            }
            return indexESDATA;
        }
        private void WriteIndexes()
        {
            string pathIndexes = AppDomain.CurrentDomain.BaseDirectory + "\\Logs\\Indexes";
            string pathIndexesFile = AppDomain.CurrentDomain.BaseDirectory + "\\Logs\\Indexes\\IndexData.txt";

            if (!Directory.Exists(pathIndexes))
            {
                Directory.CreateDirectory(pathIndexes);
            }

            if (!File.Exists(pathIndexesFile))
            {
                // Create a file to write to.   
                using (StreamWriter sw = File.CreateText(pathIndexesFile))
                {
                    sw.WriteLine("indexESDATA:" + indexESDATA); //make the same for the other kinds
                }
            }
            else
            {
                File.Delete(pathIndexesFile);
                File.Delete(pathIndexesFile);
                using (StreamWriter sw = File.CreateText(pathIndexesFile))
                {
                    sw.WriteLine("indexESDATA:" + indexESDATA); //make the same for the other kinds
                }
            }

        }
        private void EvaluatePerformance(object source, ElapsedEventArgs e)
        {
            //Calculates the time passed since the creation
            DateTime baseDate = new DateTime(1970, 1, 1);
            TimeSpan diff = DateTime.Now - baseDate;
            double milisTime = diff.TotalMilliseconds;
            long timeCheck = Convert.ToInt64(milisTime);

            //Getting the directories on the path
            string path = AppDomain.CurrentDomain.BaseDirectory + "Logs\\Data";
            string[] directories = Directory.GetDirectories(path);

            foreach (string directory in directories)
            {
                //Getting Files
                string[] fileEntries = Directory.GetFiles(directory);
                foreach (string filePath in fileEntries)
                {

                    //get the timestamp of the file
                    string[] timestampObtain = filePath.Split(new[] { "_ts_" }, StringSplitOptions.None);
                    string[] timestamp = timestampObtain[1].Split('.');
                    long timestampFile = Convert.ToInt64(timestamp[0]);

                    //If the alert is on the block time we ignore it
                    if (timeCheck - timestampFile > updateTimeEvaluation) //to be changed
                    {
                        //nothing happens, we dont treat this file anymore, too old
                        File.Delete(filePath);
                        WriteToFileActions("\n[" + DateTime.Now + "] File " + Path.GetFileName(filePath) + " deleted because the actions already took place.");
                    }
                    else
                    {
                        long result = timeCheck - timestampFile;
                        WriteToFileActions("\n[" + DateTime.Now + "] Analysing " + Path.GetFileName(filePath));

                        //variables used for stocking the file information
                        string information;
                        List<string> informations = new List<string>();

                        StreamReader sr = new StreamReader(filePath);
                        while ((information = sr.ReadLine()) != null)
                        {
                            informations.Add(information);
                        }

                        sr.Close();
                        string machineType = "untyped";
                        string machineId = "ALL";

                        foreach (string line in informations)
                        {
                            string[] infoSplited = line.Split(':');
                            if (infoSplited[0] == "machineType")
                            {
                                machineType = infoSplited[1];
                            }
                            else if (infoSplited[0] == "machineId")
                            {
                                machineId = infoSplited[1];
                            }
                        }

                        string pathMetrics = AppDomain.CurrentDomain.BaseDirectory + "\\Logs\\Metrics\\" + machineType + ".txt";
                        string metric;
                        List<string> metrics = new List<string>();

                        StreamReader srMetrics = new StreamReader(pathMetrics);
                        while ((metric = srMetrics.ReadLine()) != null)
                        {
                            metrics.Add(metric);
                        }
                        srMetrics.Close();

                        foreach (string line in informations)
                        { 
                            string[] infoSplited = line.Split(':');
                            switch (infoSplited[0])
                            {
                                default:
                                    //WriteToFile("Metric " + infoSplited[0] + " not found on the metrics criteria");
                                    break;
                                case "machineType":
                                    break;
                                case "machineId":
                                    break;
                                case "timeStamp":
                                    break;
                                case "metric1":
                                    analyseRequest("metric1", metrics, machineType, infoSplited,filePath);
                                    break;
                                case "metric2":
                                    analyseRequest("metric2", metrics, machineType, infoSplited, filePath);
                                    break;
                                case "metric3":
                                    analyseRequest("metric3", metrics, machineType, infoSplited, filePath);
                                    break;

                            }
                        }
                    }
                }
            }
        }
        private int GetMetric(List<string> Metrics, string meticName)
        {
            foreach (string a in Metrics)
            {
                string[] toCompare = a.Split(':');
                if (toCompare[0] == meticName)
                {
                    return Convert.ToInt32(toCompare[1]);
                }
            }
            return 0;
        }
        private int analyseRequest(string metricName, List<string> metrics, string machineType, string[] infoSplited, string filePath)
        {
            int threshold;
            threshold = GetMetric(metrics, metricName);
            if (threshold == 0)
            {
                WriteToFileActions("Metric 1 threshold not found");
                return 0;
            }
            else
            {
                if (Convert.ToInt64(infoSplited[1]) >= threshold)
                {
                    DateTime baseDate = new DateTime(1970, 1, 1);
                    TimeSpan diff = DateTime.Now - baseDate;
                    double milisTime = diff.TotalMilliseconds;
                    long timeCheck = Convert.ToInt64(milisTime);

                    if (machineType == "AS_WEB")
                    {   
                        //Create machine function
                        if (timeCheck- timeMillisecond < 150000)
                        {
                            long timeLeft = 150000 - (timeCheck - timeMillisecond);
                            long timeLeftSeconds = timeLeft / 1000;

                            WriteToFileActions("Still in cooldown, refused to create a new instance, time left " + timeLeft + " milliseconds");
                        }
                        else
                        {
                            bool picked = false;
                            int index = 0;
                            string[] nameCutted = null;
                            while (!picked)
                            {
                                if (ASMachinesStatus[index, 2] == "down")
                                {
                                    picked = true;
                                    nameCutted = ASMachinesStatus[index, 0].Split('W');
                                    ASMachinesStatus[index, 2] = "up";
                                    //Calculates the time passed since the creation
                                    timeMillisecond = timeCheck;
                                    writeToCooldownFile();
                                }
                                index = index + 1;
                            }
                            WriteToFileActions(ASMachinesStatus[index, 2]);
                            WriteToFileActions("Creating machine AS_WEB " + nameCutted[1]);
                            WriteIndexesAS();
                            cooldownAS = true;
                        }
                    }
                    else if (machineType == "ES")
                    {
                        //Create machine ES
                        WriteToFileActions("--->" + Path.GetFileName(filePath) + " , Metric " + infoSplited[0] + ":" + infoSplited[1] + " overpasses " + threshold);
                        //trigers actions
                        using (PowerShell PowerShellInstance = PowerShell.Create())
                        {
                            //A adapter
                            string lastIndex = indexESDATA;
                            string newindexESDATA = GetNextESData();
                            indexESDATA = newindexESDATA;
                            PowerShellInstance.AddScript("(Get-Content -Path C:\\Users\\Fernandezblanco\\source\\repos\\DavidLys\\TCPServerTest\\TCPServerTest\\bin\\Debug\\Scripts\\Terraform\\TerraformESDataVM\\variablesDynamic.tf -Raw) -replace '" + lastIndex + "', '" + newindexESDATA + "' | Set-Content -Path C:\\Users\\Fernandezblanco\\source\\repos\\DavidLys\\TCPServerTest\\TCPServerTest\\bin\\Debug\\Scripts\\Terraform\\TerraformESDataVM\\variablesDynamic.tf");
                            PowerShellInstance.AddScript("(Get-Content -Path C:\\Users\\Fernandezblanco\\source\\repos\\DavidLys\\TCPServerTest\\TCPServerTest\\bin\\Debug\\Scripts\\Powershell\\ES_DATA\\ES_DATA.ps1 -Raw) -replace 'LOGS_ES_DATA_" + lastIndex + "', 'LOGS_ES_DATA_" + newindexESDATA + "' | Set-Content -Path C:\\Users\\Fernandezblanco\\source\\repos\\DavidLys\\TCPServerTest\\TCPServerTest\\bin\\Debug\\Scripts\\Powershell\\ES_DATA\\ES_DATA.ps1");
                            PowerShellInstance.Invoke();

                            PowerShellInstance.AddScript("cd C:\\Users\\Fernandezblanco\\source\\repos\\DavidLys\\TCPServerTest\\TCPServerTest\\bin\\Debug\\Scripts\\Powershell\\ES_DATA\\");
                            string readText = File.ReadAllText("C:\\Users\\Fernandezblanco\\source\\repos\\DavidLys\\TCPServerTest\\TCPServerTest\\bin\\Debug\\Scripts\\Powershell\\ES_DATA\\ES_DATA.ps1");

                            PowerShellInstance.AddScript(readText);
                            PowerShellInstance.Invoke();
                            WriteToLogFile("script done");
                        }
                    }
                }
                return 0;
            }
        }

        private void WriteIndexesAS()
        {
            string pathIndexesFile = AppDomain.CurrentDomain.BaseDirectory + "Resources\\CREATE_VM_FROM_IMAGE\\IPConfigs\\ipFix.txt";
            if (!File.Exists(pathIndexesFile))
            {
                // Create a file to write to.   
                using (StreamWriter sw = File.CreateText(pathIndexesFile))
                {
                    int i = 0;
                    for (i = 0; i < 5; i++)
                    {
                        if (ASMachinesStatus[i, 0] != "")
                        {
                            WriteToLogFile(ASMachinesStatus[i, 0] + "," + ASMachinesStatus[i, 1] + "," + ASMachinesStatus[i, 2]);
                        }
                    }
                }
            }
            else
            {
                File.Delete(pathIndexesFile);
                using (StreamWriter sw = File.CreateText(pathIndexesFile))
                {
                   
                    int i = 0;
                    for (i = 0; i < 5; i++)
                    {
                        if (ASMachinesStatus[i, 0] != "")
                        {
                            sw.WriteLine(ASMachinesStatus[i, 0] + "," + ASMachinesStatus[i, 1] + "," + ASMachinesStatus[i, 2]);
                        }
                    }
                }
            }

        }

        private void createAS(string indexAS)
        {
            //.\createMachine.ps1 -location "West Europe" -ResourceGroupName "WE-QA-G" -vnetName "WE-QA-G-VNET" -vsubnetName "AS" -index "000001" -sprintNumber "174"
        }

        protected override void OnStop()
        {
            WriteToLogFile("Service is stopped at " + DateTime.Now);
            WriteIndexes();
        }
        private void OnElapsedTime(object source, ElapsedEventArgs e)
        {
            WriteToLogFile("Service is recall at " + DateTime.Now);
        }
        public void WriteToLogFile(string Message)
        {
            string path = AppDomain.CurrentDomain.BaseDirectory + "\\Logs";
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
            string filepath = AppDomain.CurrentDomain.BaseDirectory + "\\Logs\\ServiceLogs\\ServiceLog_" + DateTime.Now.Date.ToShortDateString().Replace('/', '_') + ".txt";
            if (!File.Exists(filepath))
            {
                // Create a file to write to.   
                using (StreamWriter sw = File.CreateText(filepath))
                {
                    sw.WriteLine(Message);
                }
            }
            else
            {
                using (StreamWriter sw = File.AppendText(filepath))
                {
                    sw.WriteLine(Message);
                }
            }
        }
        public void WriteToFileActions(string Message)
        {
            string path = AppDomain.CurrentDomain.BaseDirectory + "\\Logs\\Actions";
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
            string filepath = AppDomain.CurrentDomain.BaseDirectory + "\\Logs\\Actions\\ServiceLog_" + DateTime.Now.Date.ToShortDateString().Replace('/', '_') + ".txt";
            if (!File.Exists(filepath))
            {
                // Create a file to write to.   
                using (StreamWriter sw = File.CreateText(filepath))
                {
                    sw.WriteLine(Message);
                }
            }
            else
            {
                using (StreamWriter sw = File.AppendText(filepath))
                {
                    sw.WriteLine(Message);
                }
            }
        }
    }
}