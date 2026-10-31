import { useBackend } from 'tgui/backend';

import { Window } from '../layouts';

type Data = {
  nanite_cans: NaniteCan[];
};

type NaniteCan = {
  nanites: number;
};

export const HullCrucible = (props) => {
  const { act, data } = useBackend<Data>();
  const { nanite_cans = [] } = data;
  return (
    <Window width={100} height={100}>
      <Window.Content>
        {nanite_cans.map((can) => {
          {
            can.nanites;
          }
        })}
      </Window.Content>
    </Window>
  );
};
