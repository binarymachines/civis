#!/usr/bin/env python

import json
import uuid
from snap import common
from mercury.dataload import DataStore
from mercury.mlog import mlog, mlog_err

'''
date_month = date_tokens[0]
date_day = date_tokens[1]
date_year = date_tokens[2]

day_id = olap.dim_id_for_value('dim_date_day', int(date_day))
month_id = olap.dim_id_for_value('dim_date_month', int(date_month))
year_id = olap.dim_id_for_value('dim_date_year', int(date_year))

'''

class ObjectFactory(object):
    
    @classmethod
    def create_db_object(cls, table_name, db_svc, **kwargs):
        DbObject = getattr(db_svc.Base.classes, table_name)
        return DbObject(**kwargs)


def to_boolean(value: str):

    if not value:
        return False
    
    if value.lower() == 'yes':
        return True
    
    if value.lower() == 'no':
        return False


class PostgresDatastore(DataStore):

    def __init__(self, service_object_registry, *channels, **kwargs):
        super().__init__(service_object_registry, *channels, **kwargs)


    def write_voter_data(self, voter_record, db_service, **write_params):

        new_id = None

        voter_record.pop('party')
        voter_record['id'] = str(uuid.uuid4())

        apt_string = voter_record.get('apartment', '')
        if apt_string is not None:
            voter_record['apartment'] = apt_string.strip()
       

        with db_service.txn_scope() as session:

            db_rec = ObjectFactory.create_db_object('voters', db_service, **voter_record)
            session.add(db_rec)
            session.flush()
            new_id = str(db_rec.id)

        return new_id
    

    def write(self, records, **write_params):

        postgres_svc = self.service_object_registry.lookup('postgres')        
        record_type = write_params.get('record_type')

        for raw_rec in records:

            rec = json.loads(raw_rec)

            if record_type == 'voter':
                try:
                    self.write_voter_data(rec, postgres_svc)

                    """
                    output_rec = {                        
                        'van_record_id': rec['voter_id_org'], # TODO: change to van_id on next full ingest
                        'voter_id': id
                    }

                    print(json.dumps(output_rec))
                    """
                    
                except Exception as err:
                    mlog_err(err, issue=f"Error ingesting voter record.", record=rec)

            else:
                mlog(Exception(f'Unrecognized record type {record_type}'))

     

