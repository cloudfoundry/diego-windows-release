using System;
using System.Collections.Generic;

namespace Utilities
{
    public class Config
    {
        public static Dictionary<string, string> Params()
        {
            var javaScriptSerializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            var jsonString = System.IO.File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + "parameters.json");
            return javaScriptSerializer.Deserialize<Dictionary<string, string>>(jsonString);
        }
    }
}
