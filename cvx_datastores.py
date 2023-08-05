#!/usr/bin/env python

import json
import uuid
from snap import common
import cvx_utils as utils
from mercury.dataload import DataStore
from mercury.mlog import mlog, mlog_err
from collections import namedtuple

'''
date_month = date_tokens[0]
date_day = date_tokens[1]
date_year = date_tokens[2]

day_id = olap.dim_id_for_value('dim_date_day', int(date_day))
month_id = olap.dim_id_for_value('dim_date_month', int(date_month))
year_id = olap.dim_id_for_value('dim_date_year', int(date_year))

'''

REF_PARTY_LOOKUP = {
    'DEM': 1,
    'REP': 2,
    'NOPTY': 3 
}

VotingEvent = namedtuple('VotingEvent', 'election_date election_type')

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


    def get_voting_event(self, election_string):

        tokens = election_string.split('_')

        # first token is the election type

        election_type = tokens[0]

        # next three tokens are month, day, and year
        month = tokens[1]
        day = tokens[2]
        year = tokens[3]

        return VotingEvent(election_date='-'.join([month, day, year]), election_type=election_type)
    

    def lookup_election_type_id(self, election_type_str):
        olap_svc = self.service_object_registry.lookup('olap')
        return olap_svc.dim_id_for_value('dim_election_type', election_type_str)
    

    def lookup_date_dimensions(self, election_date_str):

        olap_svc = self.service_object_registry.lookup('olap')
        tokens = election_date_str.split('-')

        print(f'####### Looking up dimension value for date string: {election_date_str}...')

        return {
            'dim_date_day_id': olap_svc.dim_id_for_value('dim_date_day', int(tokens[1])),
            'dim_date_month_id': olap_svc.dim_id_for_value('dim_date_month', int(tokens[0])),
            'dim_date_year_id': olap_svc.dim_id_for_value('dim_date_year', int(tokens[2]))
        }


    def write_voter_history_data(self, voter_db_record, voting_history_record, db_service, **write_params):

        for election, voted in voting_history_record.items():

            # The bulk of these entries will be empty strings
            if voted is None:
                continue

            voted_y_n = voted.strip()
            if not len(voted_y_n):
                continue
            else:
                
                did_vote = utils.to_boolean(voted_y_n)
                if did_vote:

                    vote_event = self.get_voting_event(election)

                    vote_fact_rec = {
                        'id': uuid.uuid4(),
                        'voter_id': voter_db_record.id,
                        'van_id': voter_db_record.van_id,
                        'ref_party_id': voter_db_record.ref_party_id,
                        'event_datestamp': vote_event.election_date,
                        'precinct': voter_db_record.precinct,
                        'ward': voter_db_record.ward,
                        'dim_election_type_id': self.lookup_election_type_id(vote_event.election_type)
                    }

                    vote_fact_rec.update(self.lookup_date_dimensions(vote_event.election_date))
                    with db_service.txn_scope() as session:
                        db_rec = ObjectFactory.create_db_object('fact_vote', db_service, **vote_fact_rec)
                        session.add(db_rec)


    def write_voter_data(self, voter_record, db_service, **write_params):

        party_name = voter_record.pop('party')
        voter_record['id'] = str(uuid.uuid4())
        voter_record['ref_party_id'] = REF_PARTY_LOOKUP[party_name]
        
        apt_string = voter_record.get('apartment', '')
        if apt_string is not None:
            voter_record['apartment'] = apt_string.strip()
       
        voter_db_record = None
        with db_service.txn_scope() as session:

            db_rec = ObjectFactory.create_db_object('voters', db_service, **voter_record)
            session.add(db_rec)
            session.flush()            
            voter_db_record = db_rec

        return voter_db_record
    

    def write(self, records, **write_params):

        postgres_svc = self.service_object_registry.lookup('postgres')        
        record_type = write_params.get('record_type')

        for raw_rec in records:

            rec = json.loads(raw_rec)

            if record_type == 'voter':
                try:
                    history = rec.pop('history')
                    voter = self.write_voter_data(rec, postgres_svc)
                    history.pop('voter_id_org')
                    self.write_voter_history_data(voter, history, postgres_svc)

                except Exception as err:
                    mlog_err(err, issue=f"Error ingesting voter record.", record=rec)

            else:
                mlog(Exception(f'Unrecognized record type {record_type}'))

     

