﻿using System.Linq;

using PowerDeploy.Server.Mapping;
using PowerDeploy.Server.Model;
using PowerDeploy.Server.ServiceModel;

using Raven.Client;

using ServiceStack;

namespace PowerDeploy.Server.Services
{
    public class EnvironmentService : Service
    {
        public IDocumentStore DocumentStore { get; set; }

        public object Get(QueryEnvironment request)
        {
            using (var session = DocumentStore.OpenSession())
            {
                if (request.Id == default(int))
                {
                    return session.Query<Environment>().ToList();
                }

                return session.Load<Environment>("Environments/" + request.Id);
            }
        }

        public EnvironmentDto Put(EnvironmentDto request)
        {
            using (var session = DocumentStore.OpenSession())
            {
                var environment = session.Load<Environment>("Environments/" + request.Id);
                environment.PopulateWith(request);

                session.SaveChanges();

                return environment.ToDto();
            }
        }

        public EnvironmentDto Post(EnvironmentDto request)
        {
            using (var session = DocumentStore.OpenSession())
            {
                session.Store(request);
                session.SaveChanges();

                return request;
            }
        }

        public void Delete(DeleteEnvironment request)
        {
            using (var session = DocumentStore.OpenSession())
            {
                session.Advanced.DocumentStore.DatabaseCommands.Delete("Environments/" + request.Id, null);
                session.SaveChanges();
            }
        }
    }
}