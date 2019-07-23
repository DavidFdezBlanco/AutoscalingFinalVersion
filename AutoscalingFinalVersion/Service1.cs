using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using System.Timers;

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
                                    int threshold = 100;
                                    threshold = GetMetric(metrics, "metric1");

                                    if (Convert.ToInt32(infoSplited[1]) > threshold) //retrieves the seuil from a file
                                    {
                                        WriteToFileActions("--->" + Path.GetFileName(filePath) + " , Metric " + infoSplited[0] + ":" + infoSplited[1] + " overpasses " + threshold);
                                        //trigers actions

                                        /* adaptarlo a los AS_WEB
                                        using (PowerShell PowerShellInstance = PowerShell.Create())
                                        {
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
                                            WriteToFile("script done");
                                        }*/
                                    }
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
        protected override void OnStop()
        {
            WriteToLogFile("Service is stopped at " + DateTime.Now);
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