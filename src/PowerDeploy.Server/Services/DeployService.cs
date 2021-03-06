﻿using System;
using System.Collections.Generic;
using System.Linq;

using PowerDeploy.Core;
using PowerDeploy.Server.Indexes;
using PowerDeploy.Server.Mapping;
using PowerDeploy.Server.Model;
using PowerDeploy.Server.Provider;
using PowerDeploy.Server.ServiceModel;
using PowerDeploy.Server.ServiceModel.Deployment;

using Raven.Client;

using ServiceStack;

using Environment = PowerDeploy.Server.Model.Environment;

namespace PowerDeploy.Server.Services
{
    public class DeployService : Service
    {
        public IFileSystem FileSystem { get; set; }
        public ServerSettings ServerSettings { get; set; }
        public NugetPackageDownloader PackageDownloader { get; set; }
        public IDocumentStore DocumentStore { get; set; }

        public TriggerDeploymentResponse Post(TriggerDeployment request)
        {
            using (var session = DocumentStore.OpenSession())
            {
                var environment = session.Query<Environment>().FirstOrDefault(e => e.Name == request.Environment);

                if (environment == null)
                {
                    throw HttpError.NotFound("Environment {0} not found.".Fmt(request.Environment));
                }

                var deploymentInfo = new Deployment()
                {
                    EnvironmentId = "environments/" + environment.Id,
                    RequestedAt = DateTime.UtcNow,
                };

                var packageInfo = session.Load<Package>("packages/{0}/{1}".Fmt(request.PackageId, request.Version));

                deploymentInfo.Package = packageInfo;
                deploymentInfo.Status = DeployStatus.Deploying;
                session.Store(deploymentInfo);

                session.SaveChanges();

                using (var workspace = new Workspace(FileSystem, ServerSettings))
                {
                    var neutralPackagePath = PackageDownloader.Downloaad(request.PackageId, request.Version, workspace.TempWorkDir);

                    workspace.UpdateSources();

                    var packageManager = new PackageManager(workspace.EnviornmentPath);
                    var configuredPackage = packageManager.ConfigurePackageByEnvironment(neutralPackagePath, request.Environment, workspace.TempWorkDir);
                    packageManager.DeployPackage(configuredPackage);
                    deploymentInfo.FinishedAt = DateTime.UtcNow;
                    deploymentInfo.Status = DeployStatus.Successful;
                    session.SaveChanges();

                    return new TriggerDeploymentResponse();
                }
            }
        }

        public object Get(GetCurrentDeploymentsRequest request)
        {
            using (var session = DocumentStore.OpenSession())
            {
                var result = new List<DeploymentDto>();

                var deployments = session.Query<Deployment_Latest.ReducedResult, Deployment_Latest>()
                                         .Include<Deployment_Latest.ReducedResult>(r => r.EnvironmentId)
                                         .ToList()
                                         .Select(d => d.ToDto(session.Load<Environment>(d.EnvironmentId)))
                                         .OrderBy(d => d.Environment.Order);
                
                var bla = deployments.GroupBy(d => d.Package.NugetId);

                return bla;
            }
        }
    }
}