﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

using NUnit.Framework;

using NuGet;

using PowerDeploy.Core;
using Raven.Tests.Helpers;
using Environment = PowerDeploy.Core.Environment;
using IFileSystem = PowerDeploy.Core.IFileSystem;
using PhysicalFileSystem = PowerDeploy.Core.PhysicalFileSystem;

namespace PowerDeploy.Tests
{
    public abstract class PackageFixtures : RavenTestBase
    {
        private string _originalDirectory;
        public const string NugetServerPackagesPath = @"c:\temp\nuget.server";

        protected IFileSystem FileSystem { get; set; }

        [TestFixtureSetUp]
        public void InitTests()
        {
            _originalDirectory = System.Environment.CurrentDirectory;
            FileSystem = new PhysicalFileSystem();
        }

        protected static void MsBuild(string commandLineArguments)
        {
            var netFx = System.Runtime.InteropServices.RuntimeEnvironment.GetRuntimeDirectory();
            var msBuild = Path.Combine(netFx, "msbuild.exe");
            if (!File.Exists(msBuild))
            {
                Assert.Fail("Could not find MSBuild at: " + msBuild);
            }

            var allOutput = new StringBuilder();

            Action<string> writer = (output) =>
            {
                allOutput.AppendLine(output);
                Trace.WriteLine(output);
            };

            var result = SilentProcessRunner.ExecuteCommand(msBuild, commandLineArguments, System.Environment.CurrentDirectory, writer, e => writer("ERROR: " + e));

            if (result != 0)
            {
                Assert.Fail("MSBuild returned a non-zero exit code: " + result);
            }
        }

        // todo: read from dir
        protected Environment GetUnitEnvironment()
        {
            return new Environment()
            {
                Name = "Unit",
                Description = "UnitTest",
                Variables = new List<Variable>()
                {
                    new Variable() { Name = "xcopy.unit.variable1", Value = "Val1" }, 
                    new Variable() { Name = "xcopy.unit.variable2", Value = "Val2" }, 
                    new Variable() { Name = "SampleAppConsole_Destination", Value = @"c:\temp" },
                    new Variable() { Name = "env", Value = "UNIT" }
                }
            };
        }

        protected void Clean(string directory)
        {
            new PhysicalFileSystem().DeleteDirectory(Path.Combine(System.Environment.CurrentDirectory, directory));
        }

        protected static void AssertPackage(string packageFilePath, Action<ZipPackage> packageAssertions)
        {
            var fullPath = Path.Combine(System.Environment.CurrentDirectory, packageFilePath);
            if (!File.Exists(fullPath))
            {
                Assert.Fail("Could not find package file: " + fullPath);
            }

            Trace.WriteLine("Checking package: " + fullPath);
            var package = new ZipPackage(fullPath);
            packageAssertions(package);

            Trace.WriteLine("Success!");
        }

        [TestFixtureTearDown]
        public void CleanupTest()
        {
            System.Environment.CurrentDirectory = _originalDirectory;
            FileSystem.DeleteTempWorkingDirs();
        }
    }
}