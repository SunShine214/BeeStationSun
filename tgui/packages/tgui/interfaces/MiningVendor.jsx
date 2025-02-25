import { classes } from 'common/react';
import { useBackend } from '../backend';
import { Box, Button, Section, Table } from '../components';
import { Window } from '../layouts';

export const MiningVendor = (props) => {
  const { act, data } = useBackend();
  let inventory = [...data.product_records];
  return (
    <Window width={425} height={600}>
      <Window.Content scrollable>
        <Section title="User">
          {((data.user.access_valid || data.user.observer) && (
            <Box>
              Welcome, <b>{data.user.name || 'Unknown'}</b>, <b>{data.user.job || 'Unemployed'}</b>!
              <br />
              Your balance is{' '}
              <b>
                {data.user.points} {data.user.currency_type}
              </b>
              .
            </Box>
          )) ||
            (data.user.card_found && (
              <Box color="light-gray">
                No bank account in the card!
                <br />
                Please contact your local HoP!
              </Box>
            )) || (
              <Box color="light-gray">
                No registered ID card!
                <br />
                Please contact your local HoP!
              </Box>
            )}
        </Section>
        <Section title="Equipment">
          <Table>
            {inventory.map((product) => {
              return (
                <Table.Row key={product.name}>
                  <Table.Cell>
                    <span
                      className={classes(['vending32x32', product.path])}
                      style={{
                        verticalAlign: 'middle',
                      }}
                    />{' '}
                    <b>{product.name}</b>
                  </Table.Cell>
                  <Table.Cell>
                    <Button
                      style={{
                        minWidth: '95px',
                        textAlign: 'center',
                      }}
                      disabled={!data.user.access_valid || data.user.observer || product.price > data.user.points}
                      content={product.price + ' points'}
                      onClick={() =>
                        act('purchase', {
                          'ref': product.ref,
                        })
                      }
                    />
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
