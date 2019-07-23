using System;
using System.Collections;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Threading;

namespace AutoscalingFinalVersion
{
    public class MyHttpServer : HttpServer
    {
        public MyHttpServer(int port)
            : base(port)
        {
            WriteToFile("HTTP Server Initialized Listening on port: " + port);
        }
        public override void handleGETRequest(HttpProcessor p)
        {
            //Add get request rules if u want, we dont use it
            //WriteToFile("*** request: " + p.http_url);
            p.writeFailure();
            p.outputStream.WriteLine("Unauthorized get request");
        }

        public override void handlePOSTRequest(HttpProcessor p, StreamReader inputData)
        {
            WriteToFile("*** POST request:" + p.http_url + "treated and metrics stocked \n");
            p.writeSuccess();
            p.outputStream.WriteLine("<html><body><h1>Request Treated {0}</h1>", p.http_url);
        }

        public void WriteToFile(string Message)
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
    }
}
