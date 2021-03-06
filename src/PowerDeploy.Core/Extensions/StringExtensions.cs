﻿using System.IO;
using System.Xml;
using System.Xml.Serialization;

namespace PowerDeploy.Core.Extensions
{
    public static class StringExtensions
    {
        public static T FromXml<T>(this Stream xmlStream) where T : class
        {
            var serializer = new XmlSerializer(typeof(T));
            var result = serializer.Deserialize(new XmlTextReader(new StreamReader(xmlStream))) as T;

            return result;
        }
    }
}